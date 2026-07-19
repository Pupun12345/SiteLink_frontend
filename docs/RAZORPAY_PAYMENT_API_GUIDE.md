# Razorpay Subscription Payments — Backend Kya Banana Hai

Worker aur Vendor dono ke "Plans" screens ab real Razorpay payment se subscribe/upgrade karte hain. Flutter app ne apni taraf se sab kar liya hai — is doc me sirf **backend** ka kaam hai: 2 naye endpoints + Razorpay Orders API se integration.

Base URL: `https://sitelink-backend-4.onrender.com`

---

## ⚠️ Keys — kahan jaati hain (IMPORTANT)

```
RAZORPAY_KEY_ID=rzp_test_T0CJxzVeZJBxqQ
RAZORPAY_KEY_SECRET=GEdl1kGCLbcn964zxNYp0isQ
```

- **`KEY_ID`** — public hai, Flutter app me already hai (checkout kholne ke liye). Koi issue nahi.
- **`KEY_SECRET`** — **sirf backend `.env` me daalo, kabhi bhi git me commit mat karo, kabhi bhi app/frontend ko mat bhejo.** Isi se payment signature verify hoti hai — leak hui to koi bhi fake "payment successful" bana sakta hai.

`.env`:
```
RAZORPAY_KEY_ID=rzp_test_T0CJxzVeZJBxqQ
RAZORPAY_KEY_SECRET=GEdl1kGCLbcn964zxNYp0isQ
```

Node backend me `razorpay` npm package use karo (`npm install razorpay`), ya direct REST call (Basic Auth `key_id:key_secret`).

---

## Flow (kyun 2 endpoint chahiye)

```
App                          Backend                        Razorpay
 │  1. POST create-order ──▶ │                                 │
 │                           │  2. Orders API se order banao ─▶│
 │                           │  ◀── order_id, amount ──────────│
 │  ◀── orderId, amount ──── │                                 │
 │                                                              │
 │  3. Razorpay Checkout khulta hai (native UI) ───────────────▶│
 │  ◀── payment_id, order_id, signature ────────────────────────│
 │                                                              │
 │  4. POST verify-payment ▶│                                  │
 │      (in teeno cheezein) │  5. Signature verify (HMAC) ──── │
 │                           │  6. Subscription activate karo   │
 │  ◀── success ──────────── │                                 │
```

Checkout ka "success" callback client-side hai — usko blindly trust nahi karte. Signature verify (step 5) hi asli proof hai ki payment genuine hai.

---

## 1. `POST /api/payments/create-order`

**Auth:** Bearer token required (`req.user`).

**Request:**
```json
{ "planId": "665f1a2b3c4d5e6f7a8b9c0d" }
```

**Kya karna hai:**
1. `planId` se plan dhundo (existing `Plan` collection — jisse `GET /plans/plans` data deta hai). `price` field chahiye (rupees me, e.g. `2999`).
2. Razorpay Orders API call karo:
```js
const razorpay = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });
const order = await razorpay.orders.create({
  amount: plan.price * 100,       // paise me — 2999 rupees = 299900
  currency: 'INR',
  receipt: `plan_${planId}_${req.user.id}_${Date.now()}`,
  notes: { userId: req.user.id.toString(), planId: planId },
});
```
3. Response:
```json
{
  "success": true,
  "data": {
    "orderId": "order_ABC123xyz",
    "amount": 299900,
    "currency": "INR",
    "keyId": "rzp_test_T0CJxzVeZJBxqQ"
  }
}
```

**Errors:**
| HTTP | Kab |
|---|---|
| `401` | Token missing/invalid |
| `404` | `planId` galat — plan nahi mila |
| `500` | Razorpay API call fail |

---

## 2. `POST /api/payments/verify-payment`

**Auth:** Bearer token required.

**Request** (Razorpay checkout se app ko yehi 3 fields milti hain, wahi yahan bhejta hai):
```json
{
  "planId": "665f1a2b3c4d5e6f7a8b9c0d",
  "razorpay_order_id": "order_ABC123xyz",
  "razorpay_payment_id": "pay_XYZ789abc",
  "razorpay_signature": "5a8e...hex..."
}
```

**Kya karna hai:**
1. **Signature verify** (ye step skip mat karna — yahi security hai):
```js
const crypto = require('crypto');
const generated = crypto
  .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
  .update(`${razorpay_order_id}|${razorpay_payment_id}`)
  .digest('hex');

if (generated !== razorpay_signature) {
  return res.status(400).json({ success: false, message: 'Invalid payment signature' });
}
```
2. Signature valid ho to — user ki subscription activate/extend karo:
   - `plan.duration` se expiry calculate karo (e.g. `'Month'` → `+1 month`, `'Year'` → `+1 year` from today, ya existing expiry se agar already active hai — extend).
   - `User`/`Subscription` document me: `activePlan: planId`, `subscriptionStatus: 'active'`, `subscriptionExpiresAt: <calculated date>`, `lastPaymentId: razorpay_payment_id` save karo.
3. Response:
```json
{
  "success": true,
  "message": "Subscription activated!",
  "data": { "expiryDate": "2026-08-17T00:00:00.000Z" }
}
```

**Errors:**
| HTTP | message | Kab |
|---|---|---|
| `400` | `Invalid payment signature` | Signature match nahi hui (fraud attempt ya galat data) |
| `404` | `Order not found` / `Plan not found` | Galat planId/orderId |
| `401` | — | Token missing/invalid |

---

## 3. Plans seed karo (agar abhi nahi hain)

App `GET /plans/plans` se hi plans padhti hai (already existing endpoint, userType-filtered). `create-order` ko kaam karne ke liye in plans ka DB record hona zaroori hai:

| userType | name | price | duration |
|---|---|---|---|
| `worker` | Worker Premium | 299 | Year |
| `vendor` | Standard Plan | 2999 | Month |
| `vendor` | Premium Plan | 4999 | Month |

Agar ye records nahi hain, app design ke exact static price dikha degi (fallback UI) lekin "Subscribe"/"Upgrade" tap karne par "Plan available nahi hai" error aayega — kyunki `planId` hi nahi hai order banane ke liye. **Ye records DB me hona zaroori hai** payment kaam karne ke liye.

---

## 4. Testing (Razorpay TEST mode — key `rzp_test_...` hai)

Razorpay ki official test card: `4111 1111 1111 1111`, koi bhi future expiry, CVV `123`. Test UPI: `success@razorpay`. In se real paisa nahi katega.

---

## Summary

| Kaam | Endpoint | Naya? |
|---|---|---|
| Order banao | `POST /payments/create-order` `{planId}` | ✅ Naya |
| Payment verify + activate | `POST /payments/verify-payment` `{planId, razorpay_order_id, razorpay_payment_id, razorpay_signature}` | ✅ Naya |
| Plans list (already app use karti hai) | `GET /plans/plans` | Existing — bas Standard/Premium vendor plans seed karne hain |

Deploy (Render Manual Deploy) hone ke baad payment flow live ho jaayega — koi Flutter change nahi lagega.
