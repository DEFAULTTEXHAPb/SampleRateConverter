import os.path as path
name = path.splitext(path.basename(__file__))[0]
tests_dir = path.dirname(__file__)
hdl_dir = path.abspath(path.join(tests_dir, '..', '..', 'hdl'))
print(name)
print(tests_dir)
print(hdl_dir)