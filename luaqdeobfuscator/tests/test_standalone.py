"""Offline regressions of captures acquired with no executor, plus the bootstrap shim."""
import json,subprocess,sys,tempfile,unittest,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from luaq.cli import binary
class StandaloneCaptureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory();cls.work=Path(cls.temp.name);cls.outputs={};cls.luau=binary('luau',None)
        for name in ['sample2','sample3','sample4']:
            out=cls.work/name
            result=subprocess.run([sys.executable,str(ROOT/'luaq.py'),'recover',str(ROOT/'tests/fixtures'/('standalone_'+name+'.jsonl')),'--out',str(out)],capture_output=True,text=True,timeout=60)
            if result.returncode:raise RuntimeError(result.stdout+result.stderr)
            cls.outputs[name]=out
    @classmethod
    def tearDownClass(cls):cls.temp.cleanup()
    def test_standalone_captures_are_complete_and_application_was_skipped(self):
        for name,out in self.outputs.items():
            report=json.loads((out/'report.json').read_text());self.assertTrue(report['all_constants_recovered']);self.assertTrue(report['all_packet_records_recovered']);self.assertEqual(report['unresolved_regions'],0)
            rows=[json.loads(x)for x in (out/'capture.jsonl').read_text().splitlines()]
            self.assertTrue(any(x.get('kind')=='application_execution_skipped'for x in rows))
    def test_standalone_roundtrip_output(self):
        result=subprocess.run([str(self.luau),str(self.outputs['sample3']/'decoded.luau')],capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr.decode());self.assertEqual(result.stdout,(ROOT/'examples/roundtrip_expected.txt').read_bytes())
    def test_standalone_sample2_behavior(self):
        out=self.outputs['sample2'];fixture=(ROOT/'tests/fixtures/sample2_behavior.luau').read_text().replace('__GENERATED_SOURCE__',json.dumps((out/'decoded.luau').read_text()));p=out/'behavior.test.luau';p.write_text(fixture)
        result=subprocess.run([str(self.luau),str(p)],capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr.decode());self.assertEqual(len(result.stdout.splitlines()),9)
    def test_clean_lighting_source_matches_executor_and_standalone(self):
        from luaq.lift import literal
        fixture=ROOT/'tests/fixtures'
        sources={'executor':(fixture/'lighting_executor_decoded.luau').read_text(),'standalone':(self.outputs['sample4']/'decoded.luau').read_text(),'clean':(fixture/'lighting_clean.lua').read_text()}
        program=(fixture/'lighting_behavior.luau').read_text().replace('__SOURCES__',literal(sources))
        p=self.work/'lighting.test.luau';p.write_text(program);result=subprocess.run([str(self.luau),str(p)],capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr.decode());self.assertEqual(len(result.stdout.splitlines()),5)
    def test_bootstrap_compatibility_methods_without_network(self):
        try:lune=binary('lune',None)
        except ValueError:self.skipTest('Lune is not installed')
        shutil.copy2(ROOT/'luaq/templates/roblox_bootstrap.luau',self.work/'roblox_bootstrap.luau')
        source='''local c=require('./roblox_bootstrap')
local first=c.Path2DControlPoint.new(c.UDim2.fromOffset(0,0))
local second=c.Path2DControlPoint.new(c.UDim2.fromOffset(100,0))
assert(c.typeof(first)=='Path2DControlPoint')
local path=c.Instance.new('Path2D');path:SetControlPoints({first,second})
assert(path:GetPositionOnCurve(0.5).X.Offset==50)
assert(path:GetTangentOnCurve(0.5).X==1)
local copy=path:GetControlPoint(1);copy.Position=c.UDim2.fromOffset(99,99)
assert(path:GetControlPoint(1).Position.X.Offset==0)
path:UpdateControlPoint(2,c.Path2DControlPoint.new(c.UDim2.fromOffset(200,0)))
assert(path:GetPositionOnCurve(0.5).X.Offset==100)
local http=c.game:GetService('HttpService');assert(http:JSONDecode(http:JSONEncode({value=7})).value==7)
'''
        p=self.work/'shim.test.luau';p.write_text(source);result=subprocess.run([str(lune),'run',str(p)],capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr.decode())
if __name__=='__main__':unittest.main()
