interp = library('interp', 'interpolation.f90',
  link_with: const)

test_interp1_exe = executable('test_interp1', 'testinterp1.f90',
  link_with: [const, interp])
test('Interp1D', test_interp1_exe,
  suite: 'interp')

test_interp2_exe = executable('test_interp2', 'testinterp2.f90',
  link_with: [const, interp])
test('Interp2D', test_interp2_exe,
  suite: 'interp')

test('InterpOctave', octave,
  args: ['--eval', 'testinterp("' + meson.build_root() / 'output2D.dat' + '")'],
  timeout: 10,
  workdir: meson.current_source_dir(),
  suite: 'interp')

# must have .current_source_dir() for Python script
test('InterpPython', python,
  args: [meson.current_source_dir() / 'testinterp.py', meson.build_root() / 'output2D.dat'],
  timeout: 10,
  suite: 'interp')