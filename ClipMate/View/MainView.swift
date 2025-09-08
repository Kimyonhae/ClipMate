//
//  MainView.swift
//  ClipMate
//
//  Created by 김용해 on 8/21/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Query var folders: [Folder]
    @FocusState private var focusState: Bool
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject var vm: ContentView.ViewModel
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        VStack {
            searchView
            folderView
            GeometryReader { geo in
                HStack {
                    leftListView(of: geo)
                    rightDetailInfoView(of: geo)
                }
            }
        }
        .padding()
        .onAppear {
            ClipBoardUseCases.shared.getContext(context: modelContext)
            FolderUseCases.shared.getContext(context: modelContext)
            
            if folders.isEmpty { // 비어있으면 folder를 추가
                let folder = FolderUseCases.shared.loadInitFolder()
                vm.selectedFolder = folder
            }else {
                if vm.selectedFolder == nil {
                    vm.selectedFolder = folders.first
                }
            }
        }
        .contentShape(Rectangle()) // 빈 영역도 터치 가능
        .onTapGesture {
            isSearchFocused = false
            guard vm.editId != nil else { return }
            vm.editId = nil
        }
        .onChange(of: vm.selectedFolder) {
            vm.updateFocusIfNeeded()
        }
        .onChange(of: vm.selectedFolder?.clips) {
            vm.updateFocusIfNeeded()
        }
        .alert("권한 필요", isPresented: $vm.isAuthorization) {
            Button("설정 열기") {
                // 시스템 설정의 '입력 모니터링' 섹션을 직접 엽니다.
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring") {
                    NSWorkspace.shared.open(url)
                }
                
                // Exit in App
                NSApplication.shared.terminate(nil)
            }
        } message: {
            Text("앱을 사용하려면 '손쉬운 사용' 및 '입력 모니터링' 권한이 필요합니다. 시스템 설정에서 권한을 허용해주세요.")
        }
    }
    
    // TODO: 검색 뷰
    private var searchView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("", text: $vm.searchText)
                .focused($isSearchFocused)
        }
    }
    
    // TODO: 폴더 리스트 뷰
    private var folderView: some View {
        HStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(folders, id: \.id) { folder in
                        if vm.editId == folder.id {
                            folderEditField(folder)
                        } else {
                            folderLabel(folder)
                                
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal)
            Image(systemName: "folder.badge.plus")
                .padding(20)
                .border(.gray, width: 1)
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.createFolder()
                }
        }
        .border(.gray, width: 1)
    }
    
    // TODO: 폴더 수정 뷰
    @ViewBuilder
    private func folderEditField(_ folder: Folder) -> some View {
        TextField("", text: $vm.editText, onCommit: {
            vm.editId = nil
            vm.chageFolderName(change: vm.editText)
            vm.isTextFieldFocused = false
        })
        .padding(4)
        .background(.clear)
        .fixedSize()
        .focused($focusState)
        .onChange(of: focusState) {
            vm.isTextFieldFocused = focusState
        }
    }
    
    // TODO: 기본 폴더 뷰
    @ViewBuilder
    private func folderLabel(_ folder: Folder) -> some View {
        let bgColor: Color = (vm.selectedFolder?.id == folder.id) ? .blue : .gray
        
        
        ZStack(alignment: .topTrailing) {
            Text(folder.name)
                .padding(4)
                .background(bgColor)
                .clipShape(.rect(cornerRadius: 4))
                .onTapGesture {
                    if vm.vaildFolder(compare: folder) {
                        vm.editId = folder.id
                        vm.editText = folder.name
                    }else {
                        vm.selectedFolder = folder
                    }
                }
            if vm.isClosed == folder.id {
                Image(systemName: "xmark.circle.fill")
                    .offset(x: 8, y: -8)
                    .onTapGesture {
                        FolderUseCases.shared.deleteFolder(folder)
                        // 삭제 후 selectedFolder를 nil로 설정
                        if folders.isEmpty { // 비어있으면 folder를 추가
                            vm.selectedFolder = nil
                        }else {
                            if vm.selectedFolder == nil {
                                vm.selectedFolder = folders.first
                            }
                            if vm.selectedFolder?.id == folder.id {
                                vm.selectedFolder = folders.first
                            }
                        }
                    }
            }
        }
        .onHover { isHover in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                vm.isClosed = isHover ? folder.id : nil
            }
        }
    }
    
    // TODO: 왼쪽 리스트 뷰 (text and image)
    private func leftListView(of geo: GeometryProxy) -> some View {
        Group {
            VStack(spacing: 0) {
                Text("ClipBoard")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .border(.gray, width: 1)
                ScrollViewReader { scroll in
                    ScrollView {
                        ForEach(vm.sortedClips) { clip in
                            let isFocused = (vm.focusClipId == clip.id)
                            
                            HStack {
                                if let imageData = clip.image,
                                   let nsImage = NSImage(data: imageData) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 30, maxHeight: 30)
                                }else {
                                    Image(systemName: "list.clipboard")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 30, maxHeight: 30)
                                }
                                Text(clip.text ?? "Not copied Text")
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding()
                            .background(isFocused ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
                            .id(clip.id)
                        }
                    }
                    .frame(maxWidth: .infinity , maxHeight: .infinity)
                    .onChange(of: vm.focusClipId) {
                        if let id = vm.focusClipId {
                            scroll.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: geo.size.width * 0.4)
        .border(.gray, width: 1)
        .onAppear {
            if let id = vm.sortedClips.first?.id {
                vm.getFocusClip(id)
            }
        }
        .onChange(of: vm.searchText) {
            if let id = vm.sortedClips.first?.id {
                vm.getFocusClip(id)
            }
        }
    }
    
    // TODO: 오른쪽 Info 정보 (Text and Image and Date)
    private func rightDetailInfoView(of geo: GeometryProxy) -> some View {
        let detailClipBoard = vm.selectedFolder?.clips.first(where: { $0.id == vm.focusClipId })
        
        return Group {
            VStack {
                if detailClipBoard == nil {
                    TutorialView()
                } else {
                    Text(Date.clipMateDateFormat(detailClipBoard?.date ?? .now))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let imageData = detailClipBoard?.image,
                       let nsImage = NSImage(data: imageData) {
                        Text("Image")
                            .font(.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Content")
                            .font(.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(detailClipBoard?.text ?? "How's your day going")
                            .frame(maxWidth: .infinity ,maxHeight: .infinity, alignment: .top)
                            .lineSpacing(3)
                            .tracking(2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    Spacer()
                }
            }
            .padding()
        }
        .frame(maxWidth: geo.size.width * 0.6 , maxHeight: .infinity)
        .border(.gray, width: 1)
    }
}

#Preview {
    MainView()
}
