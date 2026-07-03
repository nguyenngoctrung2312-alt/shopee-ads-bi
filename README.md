# Shopee Ads BI — Web App (1 file HTML, publish qua GitHub Pages)

Web App quản lý & phân tích dữ liệu **Shopee Ads** — Upload Excel/CSV →
Đồng bộ Supabase → Dashboard BI. Toàn bộ Frontend chỉ gồm **1 file
`index.html`** (không cần cài đặt, không cần build) + **1 file SQL** để tạo
Database trên Supabase.

## Bộ file

| File | Vai trò | Có cần đưa lên GitHub Pages không? |
|---|---|---|
| `index.html` | Toàn bộ Web App (giao diện + logic). Chỉ cần sửa 2 dòng CONFIG rồi dùng. | **Bắt buộc** — đây là file duy nhất GitHub Pages thực sự chạy. |
| `.nojekyll` | File rỗng, báo GitHub bỏ qua bước build Jekyll (tránh lỗi deploy). | **Bắt buộc** — upload cùng `index.html`. |
| `supabase_schema.sql` | Chạy 1 lần trên Supabase để tạo Database (bảng, view, bảo mật RLS). | Không bắt buộc, chỉ để lưu tham khảo/tái tạo Database sau này. |
| `README.md` | File hướng dẫn này. | Không bắt buộc. |

Kiến trúc: **Frontend tĩnh (HTML/JS)** gọi thẳng **Supabase** (Postgres +
Auth) qua `supabase-js` — không có server trung gian, nên có thể host miễn
phí bằng GitHub Pages.

---

## BƯỚC 1 — Tạo Database trên Supabase

1. Vào https://supabase.com → **Start your project** → đăng nhập bằng GitHub.
2. **New project** → đặt tên (vd: `shopee-ads-bi`), đặt mật khẩu Database,
   chọn Region gần nhất (vd: Singapore) → chờ 1-2 phút khởi tạo.
3. Menu trái → **SQL Editor** → **New query** → dán **toàn bộ nội dung file
   `supabase_schema.sql`** → bấm **Run**.
4. Kiểm tra: menu **Table Editor** phải thấy 2 bảng `ads_campaign_reports`,
   `upload_history`.
5. Menu **Project Settings** (biểu tượng bánh răng) → **API** → copy 2 giá trị:
   - **Project URL**
   - **anon public** key
6. Menu **Authentication** → **Users** → **Add user** → tạo email/mật khẩu
   để đăng nhập App (có thể tạo nhiều user cho các thành viên khác).

## BƯỚC 2 — Cấu hình Supabase trong `index.html` (đã điền sẵn)

File `index.html` trong bộ này **đã được điền sẵn** Project URL và anon key
của project Supabase của bạn (khoảng dòng 117-118) — mở app lên là dùng
được ngay, không cần nhập gì thêm.

```js
const SUPABASE_URL = 'https://fphiqjdwnbegdhtkuhvb.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJI...' // anon public key
```

Nếu sau này bạn **tạo project Supabase khác** hoặc **regenerate key**, chỉ
cần mở `index.html` bằng Notepad/VS Code, sửa lại 2 dòng trên bằng giá trị
mới lấy tại Project Settings → API → Lưu file.

> `anon public key` là key công khai, an toàn khi để trong file tĩnh —
> dữ liệu đã được bảo vệ bằng Row Level Security (RLS) trong
> `supabase_schema.sql`, chỉ user đã đăng nhập mới đọc/ghi được.

## BƯỚC 3 — Publish lên GitHub Pages để chia sẻ

1. Tạo repository mới trên https://github.com (vd: `shopee-ads-bi`). Có thể
   để **Public** vì không còn chứa key bí mật nào (chỉ có anon key công khai).
2. Upload file lên repo — **bắt buộc phải có `index.html` và `.nojekyll`**
   (2 file còn lại `supabase_schema.sql`, `README.md` tuỳ chọn, để tham
   khảo sau này):
   - Cách nhanh: vào repo trên GitHub → **Add file** → **Upload files** →
     kéo thả các file (nhớ chọn cả `.nojekyll`, đây là file ẩn nên phải
     bật hiện file ẩn trong File Explorer/Finder trước khi kéo-thả) →
     **Commit changes**.
   - Hoặc dùng Git:
     ```bash
     git init
     git add .
     git commit -m "Init Shopee Ads BI"
     git branch -M main
     git remote add origin https://github.com/<username>/shopee-ads-bi.git
     git push -u origin main
     ```
3. Bật GitHub Pages: vào repo → **Settings** → **Pages** (menu trái) →
   mục **Build and deployment** → **Source**: chọn **Deploy from a branch**
   → **Branch**: chọn `main` / `root` → **Save**.
4. Chờ 1-2 phút, GitHub hiển thị link dạng:
   `https://<username>.github.io/shopee-ads-bi/`
   → Đây là link Web App để chia sẻ, dùng trên mọi thiết bị có trình duyệt.

### Xử lý lỗi khi deploy GitHub Pages

**Lỗi `Error: Deployment failed, try again later.`** hoặc mục **"All
deployments"** hiện dấu ❌ đỏ ở `github-pages` — đây là lỗi hạ tầng/build
của GitHub, **không liên quan đến file dữ liệu hay code trong app**. Xử lý
theo thứ tự sau, làm hết cả 4 bước nếu bước trước chưa hết lỗi:

1. **Thêm file `.nojekyll` vào repo (nguyên nhân phổ biến nhất)**: mặc định
   GitHub Pages build site bằng Jekyll, đôi khi gây lỗi build không rõ ràng
   với site HTML/JS thuần như bộ này. Bộ 4 file đã có sẵn file rỗng
   `.nojekyll` — nhớ **upload cả file này lên repo cùng `index.html`** (ở
   GitHub web UI, bật hiện file ẩn hoặc kéo-thả cả file `.nojekyll` vào
   cùng lúc). File này báo cho GitHub bỏ qua bước build Jekyll, serve file
   tĩnh trực tiếp.
2. **Kiểm tra file nằm đúng ở gốc repo (root)**, không nằm trong thư mục
   con. Vào tab **Code** của repo, phải thấy `index.html` ngay ngoài cùng,
   không phải trong một folder con nào.
3. **Kiểm tra Source đang chọn "Deploy from a branch"**: **Settings →
   Pages → Build and deployment → Source** → chọn **Deploy from a branch**
   → **Branch**: `main` / `root` → **Save**.
4. **Nếu repo đang Private + tài khoản GitHub Free**: chuyển sang **Public**
   tại **Settings → General → Danger Zone → Change repository visibility**
   — GitHub Pages (kể cả 2 cách trên) đều không chạy được với repo Private
   trên gói Free. An toàn vì 4 file trong bộ này không chứa secret nào.
5. **Xem log lỗi chi tiết**: vào tab **Actions** hoặc bấm vào dòng deploy bị
   lỗi trong **"All deployments"** → xem dòng báo lỗi cụ thể để biết chính
   xác nguyên nhân nếu 4 bước trên chưa hết.

Sau khi sửa, vào lại **Settings → Pages**, đợi 1-2 phút và refresh — hoặc
tạo thêm 1 commit nhỏ bất kỳ (vd: sửa README) để kích hoạt build lại.

## BƯỚC 4 — Sử dụng

1. Mở link GitHub Pages → đăng nhập bằng email/mật khẩu đã tạo ở Bước 1.6.
2. Vào **Upload dữ liệu** → nhập tên Shop → kéo-thả file Excel/CSV đúng định
   dạng báo cáo Chiến dịch/Từ khóa-Vị trí Shopee → xem kết quả kiểm tra →
   bấm **Đồng bộ lên Supabase**.
3. Vào **Dashboard** → xem KPI, biểu đồ, lọc theo Ngày/Tuần/Tháng/Quý/Năm/
   Shop/Campaign/Sản phẩm.
4. Upload file tháng mới bất cứ lúc nào — dữ liệu trùng sẽ tự **cập nhật**,
   dữ liệu mới sẽ tự **thêm**, không bao giờ tạo trùng (xem cơ chế bên dưới).

---

## Cách hoạt động (tóm tắt)

- **Upload → Database**: `index.html` đọc file bằng SheetJS/PapaParse ngay
  trên trình duyệt, đối chiếu đủ 36 cột chuẩn Shopee, báo lỗi rõ dòng/cột
  nếu sai định dạng, rồi gửi thẳng lên Supabase qua `supabase-js`.
- **Chống trùng dữ liệu**: mỗi dòng có mã định danh (`row_key`) tính từ
  Shop + Tháng/Năm + Campaign + Sản phẩm + Nội dung + Vị trí + Từ khóa +
  Ngày bắt đầu. Trùng mã → **UPDATE**; chưa có → **INSERT**. Xem chi tiết
  trong `supabase_schema.sql`.
- **Dashboard**: đọc từ view `v_ads_computed` (đã tính sẵn CPC, CPM), tổng
  hợp KPI/biểu đồ ngay trên trình duyệt.
- **Đăng nhập**: dùng Supabase Auth (email/mật khẩu), dữ liệu được khoá bằng
  Row Level Security — chỉ user đã đăng nhập mới truy cập được.

## Đổi màu thương hiệu (Logo)

Khi có Logo công ty, mở `index.html`, tìm khối `tailwind.config` ở đầu file
(mục `colors.brand`) và đổi các mã màu `#EE4D2D...` sang bộ màu thương hiệu
— toàn bộ giao diện (nút, biểu đồ, số liệu nổi bật) sẽ tự cập nhật theo.

## Giới hạn dữ liệu hiện tại (sẽ cập nhật khi có thêm Format Data)

- File nguồn hiện tại (`Data base.xlsx`) có độ chi tiết theo **Tháng**
  (không có số liệu theo từng ngày). Bộ lọc Tháng/Quý/Năm chính xác 100%;
  bộ lọc Ngày/Tuần dùng "Ngày bắt đầu" chiến dịch làm mốc tham chiếu.
- Chỉ số **Add To Cart** chưa có trong báo cáo Chiến dịch/Từ khóa-Vị trí —
  hiển thị "—" trên Dashboard, sẽ có dữ liệu khi bạn cung cấp báo cáo Shopee
  khác chứa chỉ số này (chỉ cần mở rộng, không phá vỡ cấu trúc hiện tại).
- Cột **Shop** không có trong file gốc — người dùng khai báo tên Shop ngay
  lúc Upload để hỗ trợ quản lý nhiều Shop.

## Chạy thử ở máy local (tuỳ chọn, không bắt buộc)

Có thể mở trực tiếp `index.html` bằng cách double-click (một số trình duyệt
có thể chặn gọi API do chính sách bảo mật file `file://`). Nếu gặp lỗi, chạy
một server tĩnh đơn giản rồi mở `http://localhost:8000`:

```bash
python -m http.server 8000
# hoặc: npx serve .
```

Cách khuyến nghị vẫn là dùng link GitHub Pages ở Bước 3 — ổn định và chia sẻ
được cho cả team.
