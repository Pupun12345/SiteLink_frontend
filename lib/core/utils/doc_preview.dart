// ═══════════════════════════════════════════════════════════════════
//  DOCUMENT PREVIEW — PDF (resume / certificate) ko photo ki tarah
// ═══════════════════════════════════════════════════════════════════
// Cloudinary ke free account me PDF ka seedha link band hota hai (401) —
// isliye PDF resume / experience certificate kahin dikhta hi nahi tha.
// Wahi file ".jpg" se maango to Cloudinary uska pehla page photo bana ke
// deta hai (200). Isliye har jagah PDF ko is photo se dikhate hain.

bool isPdfUrl(String? url) =>
    (url ?? '').toLowerCase().split('?').first.endsWith('.pdf');

/// Cloudinary PDF → uske pehle page ki JPG. Baaki URL waise hi.
String docPreviewUrl(String url) {
  if (!isPdfUrl(url) || !url.contains('res.cloudinary.com')) return url;
  final q = url.indexOf('?');
  final base = q == -1 ? url : url.substring(0, q);
  return '${base.substring(0, base.length - 4)}.jpg';
}
