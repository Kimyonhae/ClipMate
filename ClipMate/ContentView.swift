//
//  ContentView.swift
//  ClipMate
//
//  Created by 김용해 on 8/5/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var folders: [Folder]
    @State private var searchText: String = ""
    @EnvironmentObject private var vm: ContentView.ViewModel
    
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
            CopyAndPasteManager.shared.eventMonitor(
                copyCompleteHandler: {
                    let board = NSPasteboard.general
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                        if let copiedString = board.string(forType: .string) {
                            Task {
                                await vm.create(copiedString)
                            }
                        }
                    }
                }
            )
            
            if folders.isEmpty { // 비어있으면 folder를 추가
                let folder = FolderUseCases.shared.loadInitFolder()
                vm.selectedFolder = folder
            }else {
                vm.selectedFolder = folders.first
            }
        }
        .contentShape(Rectangle()) // 빈 영역도 터치 가능
        .onTapGesture {
            guard vm.editId != nil else { return }
            vm.editId = nil
        }
    }
    
    // TODO: 검색 뷰
    private var searchView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("", text: $searchText)
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
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal)
            Image(systemName: "folder.badge.plus")
                .padding()
                .border(.gray, width: 1)
            Image(systemName: "folder.badge.minus")
                .padding()
                .border(.gray, width: 1)
                .onTapGesture {
                    FolderUseCases.shared.deleteFolder(vm.selectedFolder)
                    // 삭제 후 selectedFolder를 nil로 설정
                    vm.selectedFolder = nil
                    vm.focusClipId = nil
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
        })
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .clipShape(.rect(cornerRadius: 4))
    }
    
    // TODO: 기본 폴더 뷰
    @ViewBuilder
    private func folderLabel(_ folder: Folder) -> some View {
        let bgColor: Color = (vm.selectedFolder?.id == folder.id) ? .blue : .gray

        Text(folder.name)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(bgColor)
            .clipShape(.rect(cornerRadius: 4))
            .onTapGesture {
                if vm.vaildFolder(compare: folder) {
                    vm.editId = folder.id
                    vm.editText = folder.name
                }else {
                    print("현재 선택된 폴더가 아닙")
                }
            }
    }
    
    // TODO: 왼쪽 리스트 뷰 (text and image)
    private func leftListView(of geo: GeometryProxy) -> some View {
        let clips = vm.selectedFolder?.clips ?? []
        let sortedClips = clips.sorted { $0.date > $1.date }
        
        return Group {
            VStack {
                Text("ClipBoard")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .border(.gray, width: 1)
                ScrollViewReader { scroll in
                    ScrollView {
                        ForEach(sortedClips) { clip in
                            let isFocused = (vm.focusClipId == clip.id)
                            
                            HStack {
                                Image(systemName: "photo.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 30, maxHeight: 30)
                                Text(clip.text ?? "없습니다")
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
            if let id = vm.selectedFolder?.clips.sorted(by: { $0.date > $1.date }).first?.id {
                vm.getFocusClip(id)
            }
        }
    }
    
    // TODO: 오른쪽 Info 정보 (Text and Image and Date)
    private func rightDetailInfoView(of geo: GeometryProxy) -> some View {
        let detailClipBoard = vm.selectedFolder?.clips.first(where: { $0.id == vm.focusClipId })
        
        return Group {
            VStack {
                Text(detailClipBoard?.date.description ?? "0000-00-00")
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Spacer()
                    Image(systemName: "photo.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 100)
                    Spacer()
                }
                .padding(.vertical)
                Text("내용")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(detailClipBoard?.text ?? "How's your day going")
                    .frame(maxHeight: .infinity, alignment: .top)
                    .lineLimit(5)
                    .lineSpacing(3)
                    .tracking(2)
            }
        }
        .frame(maxWidth: geo.size.width * 0.6 , maxHeight: .infinity)
        .border(.gray, width: 1)
    }
}

#Preview {
    ContentView()
}
