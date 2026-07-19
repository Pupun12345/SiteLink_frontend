# Auth Flow — Phone OTP + Google (Password system HATA diya)

App ka authentication ab **sirf 2 tarike** se hai — **Phone + OTP** aur **Google Sign-In**. Password-based vendor login/register/forgot/reset **poora remove** kar diya gaya hai (app side). Backend pe agar wo password endpoints bane the to unhe rehne do (koi harm nahi) — app ab unhe call nahi karti.

Base URL: `https://sitelink-backend-4.onrender.com`

---

## 1. Phone + OTP (jaisा pehle tha — unchanged)

```
POST /api/auth/register        { "phone": "9876500002" }         → OTP bhejo
POST /api/auth/verify-otp      { "phone": "...", "otp": "..." }  → login/register
POST /api/auth/resend-otp      { "phone": "..." }                → OTP dobara
```

**verify-otp success response (app yehi expect karta hai):**
```json
{
  "success": true,
  "token": "<jwt>",
  "isExist": true,
  "user": {
    "_id": "...",
    "phone": "9876500002",
    "userType": "vendor",     // "vendor" | "worker" | "" (naya user)
    "name": "...",
    "email": "..."
  }
}
```

- **Naya user** → `user.userType` khaali/absent bhejo. App use role-selection → registration pe le jaati hai.
- **Purana user** → `userType` set karo (`vendor`/`worker`) → app seedha uske home pe.

---

## 2. Google Sign-In

```
POST /api/auth/google-login
{ "firebaseIdToken": "<firebase-id-token>", "deviceToken": "<fcm>", "deviceType": "android" }
```

**Success response:**
```json
{
  "success": true,
  "token": "<jwt>",
  "isNewUser": true,
  "user": {
    "_id": "...",
    "email": "user@gmail.com",
    "name": "Ravi Kumar",
    "userType": ""            // naya user → khaali
  }
}
```

### Backend ko kya karna hai (Google)
1. `firebaseIdToken` verify karo (Firebase Admin SDK).
2. Email se user dhundo; na mile to **naya user create** karo — aur uski **`name` + `email` Google se save karo**.
3. `isNewUser` boolean bhejo (`true` = pehli baar).
4. **ZAROORI (naye "better" flow ke liye):** response ke `user` object me **`name` aur `email` hamesha bhejo** (Google se). App inhe registration form me **auto-fill** karti hai (vendor: Contact Person + Email; worker: Full Name) taaki first-time Google user ko dobara na likhna pade.
5. Naya user → `userType` khaali. App role-selection → registration pe le jaati hai.

> App logic: `isNewUser == true` **ya** `userType` khaali → role screen → registration. Warna seedha vendor/worker home.

---

## 3. First-time user ka registration (dono flows same)

Naya user (OTP ya Google) → **role select** → profile registration:
```
POST /api/profile/create/vendor   (multipart)  → userType 'vendor' set
POST /api/profile/create/worker   (multipart)  → userType 'worker' set
```
Ye pehle se hai — koi change nahi. Registration complete hone par `userType` set ho jaata hai, aage se user seedha home jaata hai.

---

## 4. Summary

| Flow | Endpoint | Backend note |
|---|---|---|
| OTP send | `POST /auth/register` | unchanged |
| OTP verify | `POST /auth/verify-otp` | `token` + `user{userType,name,email}` bhejo |
| Google | `POST /auth/google-login` | `token` + `isNewUser` + `user{name,email,userType}` — **name/email zaroor** |
| Vendor profile | `POST /profile/create/vendor` | unchanged |
| Worker profile | `POST /profile/create/worker` | unchanged |
| Password login/register/forgot/reset | — | **App ab use NAHI karti** — hata sakte ho |

**Ek hi chhota naya kaam:** Google response ke `user` me `name` + `email` consistently bhejna (prefill ke liye). Baaki sab pehle jaisा.
