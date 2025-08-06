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
    @StateObject private var vm: ContentView.ViewModel = .init()
    
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
        Group {
            VStack {
                Text("ClipBoard")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .border(.gray, width: 1)
                ScrollView {
                    ForEach(vm.selectedFolder?.clips.sorted { $0.date > $1.date } ?? []) { clip in
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
                    }
                }
                .frame(maxWidth: .infinity , maxHeight: .infinity)
            }
        }
        .frame(maxWidth: geo.size.width * 0.4)
        .border(.gray, width: 1)
    }
    
    // TODO: 오른쪽 Info 정보 (Text and Image and Date)
    private func rightDetailInfoView(of geo: GeometryProxy) -> some View {
        Group {
            VStack {
                Text("2025-08-05")
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
                Text("김건희 여사 관련 의혹을 수사하는 민중기 특검팀이 6일까지는 윤석열 전 대통령 체포영장을 집행하지 않을 것이라고 5일 밝혔다. 민중기 특검팀은 6일 김건희 여사를 소환 조사한다.특검은 이날 언론 공지를 통해 윤 전 대통령 변호인 선임서가 접수돼 변호인과 소환 조사 일정, 방식 등을 논의할 예정”이라며 오늘, 내일 중으로는 체포영장 집행 계획이 없다”고 했다.특검은 지난 1일 경기 의왕 서울구치소를 찾아 수감 중인 윤 전 대통령에 대한 체포 영장 집행을 시도했으나 윤 전 대통령이 응하지 않아 중단됐다. 이에 이르면 5일쯤 체포영장 재집행에 나설 것이란 관측이 나왔지만, 특검은 6일까지는 체포영장 집행을 하지 않기로 결정했다.양측은 전날까지 윤 전 대통령이 1일 김건희 특검팀의 체포에 불응하는 과정에서 수의(囚衣)를 벗어 이른바 ‘속옷 버티기’ 논란이 빚어진 것을 두고 치열한 신경전을 벌였다.")
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
