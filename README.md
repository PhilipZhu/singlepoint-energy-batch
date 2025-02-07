# Single-point Energy Calculation Wrapper
Smart wrapper scripts to run single-point energy calculations painlessly

# Setup
Energy calculator software can be customized. Default calculator is Orca 6.0.0 / DLPNO-CCSD(T).

To use the default software, you need to setup Orca 6.0.0:
1. install OpenMPI 4.1.6 in `${HOME}/software/orca/openmpi-4.1.6/`
2. install Orca 6.0.0 in `${HOME}/software/orca/orca_6_0_0_shared_openmpi416/`. Orca executable `orca` should be located under this directory.

In ./singlepoint source code, you can find the following sections defining paths to to the default software.
```
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${HOME}/software/orca/openmpi-4.1.6/lib"
export PATH="$PATH:${HOME}/software/orca/openmpi-4.1.6/bin"
export CALC_EXE="${HOME}/software/orca/orca_6_0_0_shared_openmpi416/orca"
```

# Usage
To use `singlepoint` with the default software (Orca 6.0.0):

`./singlepoint <structure.xyz> [<charge> [<multiplicity>]]`

XYZ file can contain multiple structures and/or distinct systems (i.e. different atom composition in each frame). Same charge and multiplicity will be used for all frames.

To run calculations in parallel, simply launch multiple `./singlepoint <structure.xyz>` jobs.
