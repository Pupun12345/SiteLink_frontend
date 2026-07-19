# Language (Hindi/English) — Backend Kya Karna Hai

App me ab poora Hindi/English localization system aa gaya hai (GetX i18n). User onboarding pe ya settings (worker + vendor dono) se language switch kar sakta hai — UI turant badal jaati hai aur choice local device pe save rehti hai.

**Backend ka kaam sirf ek chhota sa hai:** user ki language choice ko uske account pe save karna aur `GET /profile/me` me wapas bhejna, taaki reinstall / naye device pe login karne par uski bhaasha automatically restore ho jaaye.

Base URL: `https://sitelink-backend-4.onrender.com`

---

## 1. Save language — `POST /api/profile/language` (already app me wired)

App logged-in user ke language change par ye call **already** karta hai:

```
POST /api/auth ... nahi — ye profile route hai:
POST /api/profile/language
Authorization: Bearer <jwt>
Content-Type: application/json

{ "language": "hindi" }      // ya "english"
```

### Backend ko kya karna hai
- User document me ek field `language` (String, enum `['hindi','english']`, default `'english'`) add karo.
- Is endpoint pe `req.user` (JWT se) ke document me `language` update karke save karo.
- Response:
```json
{ "success": true, "message": "Language updated" }
```
- Validation: `language` sirf `hindi` ya `english`. Galat value pe `400`.

> Agar ye endpoint pehle se hai (app already call karti hai) to bas confirm karo ki wo `language` field ko **persist** kar raha hai (sirf 200 return karke bhool na jaaye).

---

## 2. Return language — `GET /api/profile/me` me field add karo (ZAROORI)

Abhi `GET /profile/me` response me `language` field **nahi aata**. Ye add karna hai:

```json
{
  "success": true,
  "data": {
    "user": {
      "_id": "...",
      "name": "...",
      "userType": "vendor",
      "language": "hindi",       // ← YE ADD KARO (user ke saved value se)
      ...baaki existing fields...
    }
  }
}
```

- Value user ke document ke `language` field se; agar set nahi hai to `"english"` (ya field chhod do — app default English le lega).
- App is field ko padh ke (`MyProfile.language`) automatically us language me switch kar deti hai — **cross-device / reinstall restore** isi se kaam karega.

---

## 3. Bas itna hi

- Koi **naya endpoint nahi** banana.
- Registration/login ke response me language bhejne ki zaroorat nahi (optional — bhejo to app respect karegi).
- SMS/OTP se koi lena-dena nahi.

### Summary
| Kaam | Endpoint | Status |
|---|---|---|
| Language save karo | `POST /api/profile/language` `{language}` | App already call karti hai — backend persist kare |
| Language wapas bhejo | `GET /api/profile/me` → `data.user.language` | **Add karna hai** |
| User model | `language` field (enum hindi/english, default english) | **Add karna hai** |

Deploy (Render Manual Deploy) ke baad app apne aap sync ho jaayegi — koi aur Flutter change nahi chahiye.
