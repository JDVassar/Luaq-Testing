"""Automatic layout discovery is exercised without selecting a pinned profile."""
import json,subprocess,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from luaq.cli import binary
class AutomaticProcessTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory();cls.work=Path(cls.temp.name);cls.outputs={};cls.luau=binary('luau',None)
        for name in ['sample2','sample3','sample4']:
            out=cls.work/name
            args=[sys.executable,str(ROOT/'luaq.py'),'process',str(ROOT/'tests/fixtures'/('protected_'+name+'.lua')),'--out',str(out)]
            if name!='sample4':args+=['--capture',str(ROOT/'tests/fixtures'/(name+'.jsonl'))]
            result=subprocess.run(args,capture_output=True,text=True,timeout=180)
            if result.returncode:raise RuntimeError(result.stdout+result.stderr)
            cls.outputs[name]=out
    @classmethod
    def tearDownClass(cls):cls.temp.cleanup()
    def test_three_randomized_layouts_discovered(self):
        expected={'sample2':(4,3332),'sample3':(6,3516),'sample4':(7,3329)}
        for name,(banks,packets)in expected.items():
            out=self.outputs[name];cfg=json.loads((out/'profile/profile.json').read_text());report=json.loads((out/'prepare_report.json').read_text())
            self.assertTrue(cfg['id'].startswith('auto-'));self.assertEqual(len(cfg['banks']),banks)
            self.assertEqual(report['bootstrap']['verified_operands'],packets)
            self.assertEqual(report['bootstrap']['unresolved_regions'],0)
            self.assertTrue((out/'capture_runner.luau').is_file())
            self.assertFalse(report['clean_source_available'])
    def test_automatically_recovered_roundtrip(self):
        out=self.outputs['sample3'];p=subprocess.run([str(self.luau),str(out/'recovery/decoded.luau')],capture_output=True,timeout=30)
        self.assertEqual(p.returncode,0,p.stderr.decode())
        self.assertEqual(p.stdout,(ROOT/'examples/roundtrip_expected.txt').read_bytes())
        report=json.loads((out/'process_report.json').read_text())
        self.assertTrue(report['application_data_recovered']);self.assertFalse(report['clean_source_available'])
    def test_automatically_recovered_second_sample(self):
        out=self.outputs['sample2'];source=(out/'recovery/decoded.luau').read_text()
        fixture=(ROOT/'tests/fixtures/sample2_behavior.luau').read_text().replace('__GENERATED_SOURCE__',json.dumps(source));test=out/'behavior.test.luau';test.write_text(fixture)
        p=subprocess.run([str(self.luau),str(test)],capture_output=True,timeout=30)
        self.assertEqual(p.returncode,0,p.stderr.decode());self.assertEqual(len(p.stdout.splitlines()),9)
    def test_no_capture_stops_at_capture_ready(self):
        report=json.loads((self.outputs['sample4']/'process_report.json').read_text())
        self.assertEqual(report['status'],'CAPTURE_READY');self.assertFalse(report['application_recovered'])
    def test_resume_imports_a_capture_without_rediscovering(self):
        job=self.outputs['sample3'];out=self.work/'resumed'
        p=subprocess.run([sys.executable,str(ROOT/'luaq.py'),'resume',str(job),'--capture',str(ROOT/'tests/fixtures/sample3.jsonl'),'--out',str(out),'--wait','--timeout','10'],capture_output=True,text=True,timeout=30)
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertTrue((out/'decoded.luau').is_file())
    def test_wait_rejects_another_build(self):
        from luaq.cli import wait_for_capture
        with self.assertRaisesRegex(ValueError,'another build'):
            wait_for_capture(ROOT/'tests/fixtures/sample2.jsonl','not-that-build',5)
    def test_wait_times_out_on_an_incomplete_file(self):
        from luaq.cli import wait_for_capture
        p=self.work/'incomplete.jsonl';p.write_text('{"format":')
        with self.assertRaisesRegex(ValueError,'Timed out'):
            wait_for_capture(p,'any',0)
    def test_malformed_input_fails_without_original_execution(self):
        path=self.work/'bad.lua';path.write_text('error("MUST NOT RUN")')
        out=self.work/'bad';p=subprocess.run([sys.executable,str(ROOT/'luaq.py'),'process',str(path),'--out',str(out)],capture_output=True,text=True,timeout=30)
        self.assertNotEqual(p.returncode,0);report=json.loads((out/'process_report.json').read_text());self.assertEqual(report['status'],'FAILED');self.assertIn('Unsupported Luaq structure',(out/'discovery.log').read_text())
if __name__=='__main__':unittest.main()
