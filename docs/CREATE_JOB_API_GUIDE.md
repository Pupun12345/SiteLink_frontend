# Create Job API — Kya Kya Bhejna Hai (Request Guide)

Vendor ke job post karne ka API. Ye guide live server par test karke banayi gayi hai — jo body neeche di hai wo actually `201 Created` deti hai.

> **App-side status:** Flutter app (`new_request_controller.dart`) ye guide already follow karta hai — `latitude`/`longitude` hamesha bheje jaate hain (safe default `"0"`/`"0"` jab tak koi location-picker UI na ho), `amenities` khaali array bhejta hai jab kuch select nahi hota, `salary` raw number jaata hai. Backend fix deploy hone ke baad bhi ye payload chalta rahega (lat/long optional ho jaayega, par bhejne me koi harm nahi).

---

## Endpoint

```
POST https://sitelink-backend-4.onrender.com/api/jobs
```

## Headers (3 zaroori)

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <aapka JWT token>` |
| `Content-Type` | `application/json` |
| `Accept` | `application/json` |

> JWT `POST /api/auth/verify-otp` se milta hai (response ka `token`). Vendor account **verified** hona chahiye warna 403.

---

## ✅ Confirmed working body (ye exact bhejo)

```json
{
  "title": "Mason Required",
  "company": "yash kumar",
  "location": "Jaipur, Rajasthan",
  "latitude": "26.9124",
  "longitude": "75.7873",
  "quantity": "1",
  "salary": 580,
  "salaryType": "daily",
  "isUrgent": true,
  "duration": "2 Weeks",
  "description": "Roles: 1 x Mason. Start 13 Jul 2026",
  "experience": "15",
  "amenities": []
}
```

Ye body ke saath live API ne `201 Created` diya. 👍

---

## Har field ka detail — kya, kaisa, zaroori ya nahi

| Field | Type | Zaroori? | Kya bhejna hai / Rules |
| --- | --- | --- | --- |
| `title` | string | ✅ Haan | Job ka title. Khaali nahi. |
| `company` | string | ✅ Haan | Company/employer ka naam. |
| `location` | string | ✅ Haan | City/area text, e.g. `"Jaipur, Rajasthan"`. |
| `description` | string | ✅ Haan | Job description. Khaali nahi. |
| `experience` | string/number | ✅ Haan | Number hona chahiye, **0 se 60** ke beech. `"15"` ya `15`. |
| `quantity` | string/number | ✅ Haan | Kitne workers chahiye. **0 se zyada.** `"1"` ya `1`. |
| `salary` | number | ✅ Haan | Number, **0 ya usse zyada.** `580` (quotes ke bina). |
| `latitude` | string | ⚠️ **Abhi bhejo** | `"26.9124"`. (Live server par abhi ye na bhejne se 500 aata hai — neeche note dekho.) |
| `longitude` | string | ⚠️ **Abhi bhejo** | `"75.7873"`. Same reason. |
| `amenities` | array | ✅ Haan (array) | Numeric amenity id ki list. Kuch nahi to **`[]` bhejo** (khaali array). |
| `salaryType` | string | ❌ Optional | `daily` / `weekly` / `monthly`. Na bhejo to default `daily`. |
| `isUrgent` | boolean | ❌ Optional | `true` / `false`. Default `false`. |
| `duration` | string | ❌ Optional | Free text, e.g. `"2 Weeks"`. |

---

## ⚠️ latitude / longitude ke baare mein (IMPORTANT)

- **Abhi live server (Render) par:** `latitude` aur `longitude` **zaroor bhejo** (string mein). Na bhejne par server crash karta hai aur `500 - Cannot read properties of undefined (reading 'trim')` aata hai.
- **Fixed code deploy hone ke baad:** ye dono **optional** ho jayenge — na bhejo to bhi chalega. (Fix GitHub par ready hai, bas Render par deploy hona baaki hai.)

👉 Safe rehne ke liye Flutter se **hamesha lat/long bhej do** — dono cases mein kaam karega.

---

## amenities kaise chunein

Pehle ye call karo (auth nahi chahiye):

```
GET https://sitelink-backend-4.onrender.com/api/amenities/grouped
```

Response mein har amenity ka numeric `id` milega. Wahi ids array mein daalo, jaise `"amenities": [1, 2]`. Kuch nahi chahiye to `[]`.

---

## Success — `201 Created`

```json
{
  "success": true,
  "message": "Job created and published successfully",
  "data": {
    "_id": "6a52321fbf032f20026420e7",
    "title": "Mason Required",
    "company": "yash kumar",
    "location": "Jaipur, Rajasthan",
    "latitude": "26.9124",
    "longitude": "75.7873",
    "quantity": "1",
    "salary": 580,
    "salaryType": "daily",
    "isUrgent": true,
    "duration": "2 Weeks",
    "description": "Roles: 1 x Mason. Start 13 Jul 2026",
    "experience": "15",
    "applicationsCount": 0,
    "status": "Open",
    "approvalStatus": "approved",
    "amenities": [],
    "likesCount": 0,
    "commentsCount": 0,
    "jobId": "REQ-20E7",
    "createdAt": "2026-07-11T12:07:59.947Z"
  }
}
```

> Job turant approve ho jaata hai (`approvalStatus: "approved"`), list mein turant dikhta hai. Store karne ke liye `data._id` use karo.

---

## Errors — kya galti par kya aayega

| HTTP | message | Kab |
| --- | --- | --- |
| `401` | `Not authorized to access this route` | Token nahi bheja. |
| `401` | `Invalid or expired token` | Token galat/expire. |
| `403` | `Account verification required for posting jobs...` | Account verified nahi hai. |
| `403` | `Only Vendor or Admin can create jobs` | Worker/customer job post nahi kar sakte. |
| `400` | `Please provide all required fields` | title/company/location/description/experience me se koi missing. |
| `400` | `Invalid salary` | salary number nahi ya negative. |
| `400` | `Experience must be between 0 and 60 years` | experience 0–60 se bahar. |
| `400` | `Quantity must be greater than 0` | quantity missing/0/negative. |
| `400` | `Amenities must be an array.` | amenities array nahi bheja (`[]` bhejo). |
| `400` | `One or more selected amenities are invalid.` | koi amenity id galat. |
| `500` | `Failed to create job` / `...'trim'` | (Current live bug) lat/long nahi bheja — upar note dekho. |

---

## Flutter/Dart — ready payload

```dart
final body = {
  "title": "Mason Required",
  "company": "yash kumar",
  "location": "Jaipur, Rajasthan",
  "latitude": "26.9124",     // hamesha bhejo (live bug ke liye)
  "longitude": "75.7873",    // hamesha bhejo
  "quantity": "1",
  "salary": 580,
  "salaryType": "daily",
  "isUrgent": true,
  "duration": "2 Weeks",
  "description": "Roles: 1 x Mason. Start 13 Jul 2026",
  "experience": "15",
  "amenities": [],
};

final res = await http.post(
  Uri.parse("https://sitelink-backend-4.onrender.com/api/jobs"),
  headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  },
  body: jsonEncode(body),
);
// res.statusCode == 201  => success, jsonDecode(res.body)["data"]["_id"]
```

---

## 1-line summary

**title, company, location, description, experience, quantity, salary, latitude, longitude, amenities([]) — ye 10 zaroor bhejo; salaryType/isUrgent/duration optional. lat/long abhi zaroori hai jab tak Render par fix deploy nahi hota.**
