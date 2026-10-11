import 'package:image_picker/image_picker.dart';

// ═══════════════════════════════════════════════════════════════════
//  IMAGE PICK — upload se pehle compress, ek hi jagah se
// ═══════════════════════════════════════════════════════════════════
// Aaj ke phone ki photo 3–8 MB ki hoti hai. Use jaisi hai waisi upload
// karne se: worker ka data kharch hota hai (aur site par zyadatar 4G
// slow hota hai), upload fail hone ke chance badh jaate hain (nginx ka
// 413), aur server par storage bharta hai.
//
// `image_picker` khud resize + re-encode kar deta hai, isliye koi extra
// dependency nahi chahiye — bas settings ek jagah honi chahiye. Pehle ye
// har call site par alag-alag thi (quality 80/85, maxWidth 1200/1600/
// koi nahi), aur experience certificate par dimension cap hi nahi tha —
// wahan poori resolution ki photo chali jaati thi.
//
// Do preset, kyunki dono ki zaroorat alag hai:
//
//   document → ID proof, experience certificate, PAN, GST. Inme TEXT
//              padhna hota hai (admin verify karta hai), isliye dimension
//              bada aur quality thodi zyada rakhte hain.
//
//   photo    → profile photo, company logo, work sample. Inhe sirf
//              dekhna hota hai, isliye zyada compress kar sakte hain.

/// Document ke liye — text readable rehna zaroori hai.
/// Typical output: ~200–500 KB (8 MB original se).
const int _kDocQuality   = 80;
const double _kDocMaxSide = 1600;

/// Photo ke liye — sirf dikhne ke liye, isliye zyada compress.
/// Typical output: ~100–250 KB.
const int _kPhotoQuality   = 75;
const double _kPhotoMaxSide = 1080;

/// ID proof / certificate / PAN / GST jaisi document image.
///
/// `maxWidth` + `maxHeight` dono dete hain — dono dene par picker aspect
/// ratio maintain karke lambi side ko cap karta hai. Sirf `maxWidth`
/// dene se portrait photo (jo document scan me aam hai) bina cap reh
/// jaati thi.
Future<XFile?> pickDocumentImage(
  ImagePicker picker,
  ImageSource source,
) =>
    picker.pickImage(
      source: source,
      imageQuality: _kDocQuality,
      maxWidth: _kDocMaxSide,
      maxHeight: _kDocMaxSide,
    );

/// Profile photo / company logo / work sample.
Future<XFile?> pickPhotoImage(
  ImagePicker picker,
  ImageSource source,
) =>
    picker.pickImage(
      source: source,
      imageQuality: _kPhotoQuality,
      maxWidth: _kPhotoMaxSide,
      maxHeight: _kPhotoMaxSide,
    );
