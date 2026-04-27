# AquaGuard iOS - Task Walkthrough (Priority x Difficulty)

Tai lieu nay tong hop cac ghi chu thay doi va sap xep theo thu tu uu tien thuc te de trien khai an toan.

## Muc tieu

- Dong bo lai IA (information architecture) cua tab + ten ViewModel/View.
- Tach quyen hien thi theo role (Citizen vs Rescuer).
- Dua lai cac tinh nang con thieu so voi web app (Guides, map layer).
- Giam trung lap chuc nang giua SOS va Rescue.

## Nhan xet hien trang (quan trong)

- `ContentView` dang gan tab bi lech y nghia:
  - Tab label "SOS" dang mo `RescueView` (camera + community reports).
  - Tab label "Rescue" dang mo `SOSView` (send rescue request + history).
- Dieu nay anh huong truc tiep toi task "doi ten viewmodel theo tab" va "an tab Rescue voi Citizen".

## Bang ke hoach uu tien

| Thu tu | Hang muc | Uu tien | Do kho | Uoc luong | Pham vi anh huong | Phu thuoc |
|---|---|---|---|---|---|---|
| 1 | Chuan hoa naming theo tab (View, ViewModel, bien/ham lien quan) | P0 | Medium-High | 1-2 ngay | Rong (routing, file names, references, localization key text) | Khong |
| 2 | Dinh tuyen lai tab va nut SOS do giua Home -> chuyen sang tab SOS | P0 | Medium | 0.5-1 ngay | `ContentView`, `HomeView`, deep link/tab state | #1 nen lam cung dot |
| 3 | Chuyen Active Alerts tu SOS sang Home | P0 | Medium | 0.5-1 ngay | `HomeView`, viewmodel lien quan, state/data source | #1, #2 |
| 4 | An tab Rescue voi Citizen, chi hien cho Rescuer role | P0 | Medium-High | 1 ngay | Tab rendering theo role, auth/user profile | #1, #2 |
| 5 | Safety tab: bo sung Guides nhu web app | P1 | Medium | 0.5-1 ngay | `SafetyView`, noi dung/section guides | Doc web app truoc |
| 6 | Them Windy map vao tab Map | P1 | High | 1-2 ngay | `FloodMapView`, web embed/WKWebView/layer switch | Quy trinh map UX |
| 7 | Xu ly nut Shelter (gan chuc nang hoac doi ten) | P2 | Low-Medium | 0.5 ngay | UI text + navigation/link feature | Nen sau #4/#6 |

## Chi tiet task theo implementation order

### 1) Chuan hoa naming theo tab (P0)

Muc tieu:
- Dat ten theo dung nghia chuc nang, vi du:
  - Luong camera + community reports -> `SOSView`/`SOSViewModel` (neu day la SOS thuc su).
  - Luong send rescue request + history -> `RescueRequestView` hoac `RescueView`.
- Doi ten bien/ham trong file de de doc va tranh confusion (`reportVM`, `showSOSForm`, ...).

Viec can lam:
- Doi ten file + struct/class + references trong toan bo project.
- Ra soat string/localization key de khop label tab.
- Build lai de fix compile break do refactor.

Rui ro:
- Sai reference trong `StateObject` init.
- Mismatch giua file name va type name.

Definition of done:
- Nhin ten tab + ten view/viewmodel la hieu dung chuc nang ngay.

---

### 2) Dinh tuyen tab + nut SOS do (P0)

Muc tieu:
- Nut SOS do tai Home tab chi thuc hien 1 hanh dong ro rang: chuyen den tab SOS.
- Tab thu tu va label khop voi man hinh dung.

Viec can lam:
- Chuan hoa `selectedTab` mapping trong `ContentView`.
- Trong `HomeView`, callback nut SOS set dung index tab.
- Kiem tra animation/chuyen tab khi nhan nut.

Definition of done:
- User bam nut SOS do -> vao dung SOS tab 100%.

---

### 3) Chuyen Active Alerts sang Home (P0)

Muc tieu:
- Home la dashboard tong quan: co Active Alerts de user thay ngay khi mo app.

Viec can lam:
- Tach component Active Alerts thanh view tai su dung duoc.
- Noi du lieu vao HomeViewModel (hoac vm phu trach moi).
- Neu SOS dang giu state tam, chuyen state sang nguon dung chung.

Definition of done:
- Home hien Active Alerts on-load, SOS khong con giu vai tro dashboard alerts.

---

### 4) Role-based tab: an Rescue voi Citizen (P0)

Muc tieu:
- Citizen khong thay tab Rescue.
- Rescuer thay tab Rescue + cac du lieu request history phu hop quyen.

Viec can lam:
- Xac dinh nguon role (auth profile/local user model).
- Render tab theo dieu kien role.
- Kiem tra index tab dong khi so tab thay doi theo role.
- Chan dieu huong vao man hinh Rescue neu khong du quyen.

Definition of done:
- Dang nhap Citizen: khong co Rescue tab.
- Dang nhap Rescuer: co Rescue tab day du.

---

### 5) Safety tab - them Guides giong web app (P1)

Muc tieu:
- Noi dung huong dan day du, thong nhat voi web.

Viec can lam:
- Doi chieu danh sach guide tren web app.
- Bo sung section/card, icon, muc do canh bao.
- Day key localization cho noi dung moi.

Definition of done:
- Safety iOS va web co bo guide cung pham vi.

---

### 6) Them Windy map vao tab Map (P1)

Muc tieu:
- User xem them lop du lieu gio/mua tren map de danh gia nhanh.

Huong tiep can de xet:
- Option A: Nhung `WKWebView` Windy trong mot sheet/fullscreen.
- Option B: Them map mode switch (FloodMap / Windy).

Viec can lam:
- Chon UX mode switch.
- Tich hop web view + loading/error state.
- Kiem tra permission/network va hieu nang.

Definition of done:
- Tu map tab co the mo Windy on-demand, hoat dong on dinh.

---

### 7) Nut Shelter - gan tac vu ro rang hoac doi ten (P2)

Muc tieu:
- Loai bo "dead button" / ten mo ho.

2 huong:
- Neu co du lieu shelter: mo danh sach shelter gan nhat (uu tien).
- Neu chua co du lieu: doi ten thanh hanh dong co that hien tai (vd. "Safe Points (Soon)").

Definition of done:
- Nut co tac vu cu the, user bam vao khong bi hut.

## Thu tu trien khai de nghi (Sprint-friendly)

### Sprint A (core UX correction)
1. Task #1 Naming refactor
2. Task #2 Tab routing + SOS red button
3. Task #3 Active Alerts -> Home
4. Task #4 Role-based Rescue tab

### Sprint B (feature parity + enhancement)
5. Task #5 Safety Guides parity
6. Task #6 Windy map integration
7. Task #7 Shelter button finalization

## Checklist test nhanh sau moi task

- Build app khong loi compile.
- Chuyen tab dung index sau khi role thay doi.
- Dang nhap Citizen/Rescuer cho ket qua tab dung quyen.
- Localization EN/VI van hien dung text.
- Regression test: SOS submit, Report camera, Map route, Safety call buttons.

