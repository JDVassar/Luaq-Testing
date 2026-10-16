"""End-to-end regressions use inert fixtures. No live network/application loader runs."""
import hashlib, json, subprocess, sys, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from luaq.cli import read_captures, validate_assets, profiles, binary

class DeobfuscatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory();cls.work=Path(cls.temp.name)
        cls.luau=binary('luau',None)
        cls.outputs={}
        for name in ['sample1','sample2','sample3']:
            out=cls.work/name
            p=subprocess.run([sys.executable,str(ROOT/'luaq.py'),'recover',str(ROOT/'tests/fixtures'/f'{name}.jsonl'),'--out',str(out)],capture_output=True,text=True)
            if p.returncode:raise RuntimeError(p.stdout+p.stderr)
            cls.outputs[name]=out
    @classmethod
    def tearDownClass(cls):cls.temp.cleanup()
    def test_profiles_intact(self):
        for path,_ in profiles():validate_assets(path)
    def test_recovery_inventory_and_compilation(self):
        for name,counts in [('sample1',(24,412,3169)),('sample2',(1,24,11)),('sample3',(13,95,132))]:
            report=json.loads((self.outputs[name]/'report.json').read_text())
            self.assertEqual((report['import_status']['prototypes'],report['import_status']['constants'],report['specialized_handlers']),counts)
            self.assertTrue(report['source_compiles'])
            self.assertTrue(report['all_constants_recovered'])
            self.assertFalse(report['every_packet_has_semantics'])
    def test_first_sample_instruction_trace(self):
        out=self.outputs['sample1'];source=(out/'decoded.luau').read_text()
        source=source.replace('local step=steps[prototype.id][frame.pc]','if prototype.id=="application_1" then print("TRACE\\t3186559037\\t"..frame.pc)end\nlocal step=steps[prototype.id][frame.pc]')
        fixture=(ROOT/'tests/fixtures/roblox_math_fixture.luau').read_text();p=out/'trace.test.luau';p.write_text(fixture+'\n'+source)
        result=subprocess.run([str(self.luau),str(p)],capture_output=True,timeout=60)
        self.assertEqual(result.returncode,0,result.stderr.decode())
        self.assertEqual(len(result.stdout.splitlines()),76443)
        self.assertEqual(hashlib.sha256(result.stdout).hexdigest(),'434d2bdb7eed25f70fb500a9b16a0cee6439ef105a9c8011a8a39197464f1d13')
    def test_second_sample_nine_behavior_fixtures(self):
        out=self.outputs['sample2'];source=(out/'decoded.luau').read_text()
        fixture=(ROOT/'tests/fixtures/sample2_behavior.luau').read_text().replace('__GENERATED_SOURCE__',json.dumps(source));p=out/'behavior.test.luau';p.write_text(fixture)
        result=subprocess.run([str(self.luau),str(p)],capture_output=True,timeout=60)
        self.assertEqual(result.returncode,0,result.stderr.decode())
        self.assertEqual(len(result.stdout.splitlines()),9)
    def test_unknown_script_is_rejected_without_execution(self):
        script=self.work/'unknown.lua';script.write_text('error("MUST NOT EXECUTE")')
        result=subprocess.run([sys.executable,str(ROOT/'luaq.py'),'inspect',str(script)],capture_output=True,text=True)
        self.assertEqual(result.returncode,3);self.assertFalse(json.loads(result.stdout)['supported'])
        result=subprocess.run([sys.executable,str(ROOT/'luaq.py'),'capture',str(script),'--out',str(self.work/'unknown_output')],capture_output=True,text=True)
        self.assertEqual(result.returncode,2);self.assertFalse((self.work/'unknown_output').exists())
    def test_mixed_builds_rejected(self):
        with self.assertRaisesRegex(ValueError,'different builds'):
            read_captures([ROOT/'tests/fixtures/sample1.jsonl',ROOT/'tests/fixtures/sample2.jsonl'])
    def test_conflicting_cleartext_rejected(self):
        original=ROOT/'tests/fixtures/sample2.jsonl';rows=[json.loads(x)for x in original.read_text().splitlines()]
        row=next(x for x in rows if x.get('kind')=='region');row['data_hex']='00'
        changed=self.work/'conflicting.jsonl';changed.write_text('\n'.join(json.dumps(x)for x in rows)+'\n')
        with self.assertRaisesRegex(ValueError,'Conflicting capture payload'):
            read_captures([original,changed])
    def test_third_build_bootstrap_import_and_operand_lift(self):
        from luaq.lift import lift
        out=self.work/'sample3-bootstrap'
        result=subprocess.run([sys.executable,str(ROOT/'luaq.py'),'import',str(ROOT/'tests/fixtures/sample3_bootstrap.jsonl'),'--phase','bootstrap','--out',str(out)],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        report=json.loads((out/'report.json').read_text())
        self.assertEqual(report['import_status']['prototypes'],43)
        self.assertEqual(report['import_status']['constants'],578)
        self.assertEqual(report['unresolved_regions'],0)
        self.assertEqual(lift(ROOT/'luaq/profiles/sample3',out,self.luau),3516)
    def test_third_application_full_output_and_return_values(self):
        out=self.outputs['sample3']
        result=subprocess.run([str(self.luau),str(out/'decoded.luau')],capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr.decode())
        self.assertEqual(result.stdout,(ROOT/'examples/roundtrip_expected.txt').read_bytes())
        source=(ROOT/'examples/roundtrip_test.luau').read_text();decoded=(out/'decoded.luau').read_text()
        harness="local original=assert(loadstring("+json.dumps(source)+"));local decoded=assert(loadstring("+json.dumps(decoded)+"));local a=table.pack(original());local b=table.pack(decoded());assert(a.n==2 and b.n==a.n);for i=1,a.n do assert(a[i]==b[i])end;assert(b[2]==139587)"
        p=out/'returns.test.luau';p.write_text(harness)
        result=subprocess.run([str(self.luau),str(p)],capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr.decode())
    def test_roundtrip_example_golden_output(self):
        result=subprocess.run([str(self.luau),str(ROOT/'examples/roundtrip_test.luau')],capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr.decode())
        self.assertEqual(result.stdout,(ROOT/'examples/roundtrip_expected.txt').read_bytes())

if __name__=='__main__':unittest.main()
