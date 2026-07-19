# Job Applicants API — Backend Implementation Flow

Vendor apne posted job ke applicants dekh sake aur unhe confirm/reject kar sake — iske liye backend me kya banana hai, poora flow.

Stack assumption: Express + Mongoose, JWT auth (`protect` middleware), existing controller pattern jaisa `editWorkerProfile` me hai (`exports.fn = async (req, res) => {...}`, try/catch, `res.status(x).json({...})`).

Flutter app (frontend) **already ready hai** in dono endpoints ke liye — models, service methods, poori UI (Applicants screen, Confirm/Reject buttons, Call button) sab ban chuke hain. Backend deploy hote hi bina kisi Flutter change ke turant kaam karega.

---

## 1. Context

Worker already `POST /api/jobs/:id/apply` se apply karta hai — iska matlab ek `JobApplication` (ya jo bhi naam hai) collection already ban rahi hai, jisme `job`, `worker`, `status`, `coverLetter`, `experience`, `createdAt` fields hain (kyunki `GET /api/jobs/getAppliedJobs` worker ko yehi data dikhata hai).

**Ab vendor side se do naye kaam chahiye:**
1. Vendor apne job ke **saare applicants dekh sake** (worker profile ke saath)
2. Vendor kisi applicant ko **confirm ya reject** kar sake

Koi naya collection nahi banana — **wahi existing Application collection** use karo, bas 2 naye routes.

---

## 2. Schema check (existing Application model)

Apna application/job-application model kholo aur confirm karo ye fields hain:

```js
const jobApplicationSchema = new mongoose.Schema({
  job:         { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
  worker:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status:      { type: String, enum: ['pending', 'shortlisted', 'confirmed', 'rejected'], default: 'pending' },
  coverLetter: { type: String },
  experience:  { type: String },
  createdAt:   { type: Date, default: Date.now }
});
```

⚠️ Agar `status` field ka enum abhi sirf `['pending', 'accepted', 'completed', ...]` jaisa kuch aur hai — to **`'confirmed'` aur `'rejected'` add karo enum me**, ya jo naam pehle se hai wahi bata do, app-side flexible match ho jaata hai (naye status string ke liye chhota Flutter change lagega).

Model ka exact naam/file pata nahi to `grep -r "coverLetter" models/` chala ke dhundh lena.

---

## 3. Naya Endpoint #1 — Applicants list

### Route
```js
// routes/jobRoutes.js (jahan baaki job routes hain, wahi file me)
router.get('/:id/applicants', protect, getJobApplicants);
```
(`protect` = wahi auth middleware jo baaki authenticated routes pe lagta hai)

### Controller
```js
// controllers/jobController.js
exports.getJobApplicants = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    if (!job) {
      return res.status(404).json({ success: false, message: 'Job not found' });
    }

    // Sirf job ka owner vendor (ya admin) applicants dekh sake
    const isOwner = job.postedBy?.toString() === req.user.id;
    const isAdmin = req.user.userType === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({ success: false, message: 'Not authorized to view applicants for this job' });
    }

    const applications = await JobApplication.find({ job: req.params.id })
      .populate('worker', 'name profileImage primarySkill skills totalExperience phone workCity workState isVerified rating')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: applications.length,
      data: applications
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
```

### Response shape (app ye expect karta hai)
```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "_id": "applicationId123",
      "worker": {
        "_id": "workerId",
        "name": "Ravi Kumar",
        "profileImage": "uploads/profiles/xyz.jpg",
        "primarySkill": "Mason",
        "skills": [{ "skillName": "Plumber" }],
        "totalExperience": 5,
        "phone": "9876543210",
        "workCity": "Jaipur",
        "workState": "Rajasthan",
        "isVerified": true,
        "rating": 4.5
      },
      "coverLetter": "I am interested in this role...",
      "experience": "5",
      "status": "pending",
      "createdAt": "2026-07-11T12:07:59.947Z"
    }
  ]
}
```

> `rating` field agar User model me nahi hai to bilkul chhod do — app usko optional treat karta hai, error nahi aayega.

---

## 4. Naya Endpoint #2 — Applicant status update (Confirm/Reject)

### Route
```js
router.put('/:id/applicants/:applicationId/status', protect, updateApplicantStatus);
```

### Controller
```js
exports.updateApplicantStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = ['pending', 'shortlisted', 'confirmed', 'rejected'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status value' });
    }

    const job = await Job.findById(req.params.id);
    if (!job) {
      return res.status(404).json({ success: false, message: 'Job not found' });
    }

    const isOwner = job.postedBy?.toString() === req.user.id;
    const isAdmin = req.user.userType === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({ success: false, message: 'Not authorized to update this application' });
    }

    const application = await JobApplication.findOne({
      _id: req.params.applicationId,
      job: req.params.id
    });
    if (!application) {
      return res.status(404).json({ success: false, message: 'Application not found for this job' });
    }

    application.status = status;
    await application.save();

    res.status(200).json({
      success: true,
      message: `Applicant ${status} successfully`
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
```

### Request body
```json
{ "status": "confirmed" }
```
(ya `"rejected"` / `"shortlisted"`)

### Success response
```json
{ "success": true, "message": "Applicant confirmed successfully" }
```

---

## 5. Existing endpoint me ek chhota addition

`GET /api/jobs` aur `GET /api/jobs/:id` ke response me **`applicationsCount` field consistently bhejo** (Create Job success response me pehle se tha: `"applicationsCount": 0`). Agar list/detail me nahi aa raha to:

```js
// job list/detail query me
const jobsWithCounts = await Promise.all(
  jobs.map(async (job) => {
    const applicationsCount = await JobApplication.countDocuments({ job: job._id });
    return { ...job.toObject(), applicationsCount };
  })
);
```

App is field se "N Applicants" badge dikhata hai — na aaye to bas `0` dikhega, crash nahi hoga, par sahi count ke liye ye zaroori hai.

---

## 6. Auth/Validation summary table

| Rule | Kaise |
|---|---|
| Token required | `protect` middleware (existing pattern) |
| Sirf job-owner dekh/update kar sake | `job.postedBy.toString() === req.user.id` check |
| Admin bhi access kar sake | `req.user.userType === 'admin'` bhi allow |
| `status` sirf 4 values | `pending \| shortlisted \| confirmed \| rejected` |
| Application us job ki honi chahiye | Query me `{ _id: applicationId, job: jobId }` dono match |

---

## 7. Error responses

| HTTP | message | Kab |
|---|---|---|
| `401` | `Not authorized to access this route` | Token missing/invalid |
| `403` | `Not authorized to view applicants for this job` | Job owner nahi ho |
| `403` | `Not authorized to update this application` | Status-update pe owner nahi |
| `404` | `Job not found` | Galat jobId |
| `404` | `Application not found for this job` | Galat applicationId ya wrong job |
| `400` | `Invalid status value` | status enum se bahar |

---

## 8. Testing checklist (Postman)

1. Vendor login → `vendorToken`
2. `GET /api/jobs` (own jobs) → `jobId` note karo (jispe applications hon)
3. Worker se pehle `POST /api/jobs/:jobId/apply` kar do (agar test data nahi hai) — worker verified hona chahiye
4. `GET /api/jobs/:jobId/applicants` with `vendorToken` → list aani chahiye, `worker` object populated
5. Doosre vendor ke token se same call → `403` aana chahiye (ownership check)
6. `PUT /api/jobs/:jobId/applicants/:applicationId/status` `{"status":"confirmed"}` → `200`
7. Dobara `GET /applicants` → us applicant ka `status: "confirmed"` dikhna chahiye

---

## 9. App-side — kuch nahi karna

Flutter app models/service methods ye exact response shapes expect karte hain:

- `lib/core/models/job_models.dart` → `JobApplicant`, `JobApplicantsResponse`, `JobModel.applicationsCount`
- `lib/core/services/api_client.dart` → `JobsApiService.getApplicants()`, `JobsApiService.updateApplicantStatus()`
- `lib/features/vendor/presentation/controllers/job_applicants_controller.dart`
- `lib/features/vendor/presentation/views/job_applicants_view.dart`

Backend deploy hote hi bina kisi Flutter change ke turant kaam karega.
