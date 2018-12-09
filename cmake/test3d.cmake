# Test parameters (change for each test)
set(TESTDIR test3d)
set(REFNAME zenodo3d)
set(REFDIR ../simulations)
set(zenodoHash 225853d43937a70c9ef6726f90666645)
set(zenodoNumber 1473195)
# --- ensure reference data is available for self-test
download_testfiles(${zenodoHash}
                   ${zenodoNumber}
                   ${REFNAME}
                   ${PROJECT_SOURCE_DIR}/${REFDIR})

# --- test main exe
run_gemini_test(Gemini3D ${TESTDIR} 900)
    
# --- evaluate output accuracy vs. reference from Matt's HPC
octave_compare(Compare3D ${TESTDIR} ${REFDIR}/${REFNAME})

matlab_compare(MatlabCompare3D ${TESTDIR} ${REFDIR}/${REFNAME})