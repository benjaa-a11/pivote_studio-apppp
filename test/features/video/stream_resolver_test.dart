import 'package:flutter_test/flutter_test.dart';
import 'package:pivote/features/video/data/services/stream_resolver/js_deobfuscator.dart';
import 'package:pivote/features/video/data/services/stream_resolver/stream_candidate_extractor.dart';
import 'package:pivote/features/video/data/services/stream_resolver/stream_token_inspector.dart';

void main() {
  group('StreamResolver - Deobfuscation & Extraction Tests', () {
    test('Extrae m3u8 directo de Clappr (ejemplo la18hd)', () {
      const htmlLa18 = '''
<!DOCTYPE html>
<html>
<head>
<script src="https://cdn.jsdelivr.net/npm/@clappr/player@0.8.0/dist/clappr.min.js"></script>
</head>
<body>
<div id="player"></div>
<script>if (!window.cdnpSandbox) var player = cdnpeer.clappr(Clappr, {"id":"2yaqpqwt","src":"https://bgvnzw5k.fubo18.com:443/dsports/mono.m3u8?token=a29e25de43ca6349f6ba550465922a14ffdb6ea6-84-1795208950-1795190950","parentId":"#player","autoPlay":false});</script>
</body>
</html>
''';

      final candidates = StreamCandidateExtractor.extract(
        htmlLa18,
        Uri.parse('https://la18hd.su/vivo/canales.php?stream=dsports'),
      );

      expect(candidates, isNotEmpty);
      final top = candidates.first;
      expect(top.url, contains('fubo18.com:443/dsports/mono.m3u8?token='));
      expect(top.score, greaterThanOrEqualTo(50));

      final expiry = StreamTokenInspector.detectExpiry(top.url);
      expect(expiry, isNotNull);
      // El token tiene fecha unix 1795208950
      expect(expiry!.year, greaterThanOrEqualTo(2026));
    });

    test('Decodifica array JS ofuscado ds / atob (ejemplo streamxhd)', () {
      // Snippet real de la estructura de streamxhd
      const htmlStreamX = '''
<script>
var playbackURL="",ds=[];
ds=[[0,"emU4Mzg3MDV4SA=="],[1,"dFk4Mzg3MTdzcg=="],[2,"WGw4Mzg3MTd2Tg=="],[3,"WVk4Mzg3MTNxTg=="]];
ds.sort((a,b)=>a[0]-b[0]);
var k=WSmaw()+twvTI();
ds.forEach(e=>{
  let v=e[1];
  playbackURL+=String.fromCharCode(parseInt(atob(v).replace(/\\D/g,''))-k)
});
function WSmaw(){return 78118;}
function twvTI(){return 760483;}
</script>
''';

      final fragments = JsDeobfuscator.decodeCharCodeArrays(htmlStreamX);
      expect(fragments, isNotEmpty);
      expect(fragments.first.varName, equals('playbackURL'));
      expect(fragments.first.text, equals('http'));
    });

    test('Dean Edwards Packer unpacker', () {
      const packed = '''
eval(function(p,a,c,k,e,d){e=function(c){return c.toString(36)};if(!''.replace(/^/,String)){while(c--){d[c.toString(a)]=k[c]||c.toString(a)}k=[function(e){return d[e]}];e=function(){return'\\w+'};c=1};while(c--){if(k[c]){p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c])}}return p}('4 3="2://1.0/5.6";',7,7,'com|host|https|playbackURL|var|live|m3u8'.split('|'),0,{}))
''';

      final unpacked = JsDeobfuscator.unpackAll(packed);
      expect(unpacked, isNotEmpty);
      expect(unpacked.first, contains('https://host.com/live.m3u8'));

      final candidates = StreamCandidateExtractor.extract(
        packed,
        Uri.parse('https://example.com/live.php'),
      );
      expect(candidates.any((c) => c.url.contains('live.m3u8')), isTrue);
    });

    test('StreamTokenInspector detecta unix timestamps en tokens de Flussonic/Akamai', () {
      const urlFlussonic = 'https://stream.net/live/mono.m3u8?token=abc-12-1795210405-1795192405';
      final exp = StreamTokenInspector.detectExpiry(urlFlussonic);
      expect(exp, isNotNull);

      const urlExpires = 'https://cdn.net/hls/canal.m3u8?expires=1795210405&sig=xyz';
      final exp2 = StreamTokenInspector.detectExpiry(urlExpires);
      expect(exp2, isNotNull);
      expect(exp!.millisecondsSinceEpoch, equals(exp2!.millisecondsSinceEpoch));
    });
  });
}
