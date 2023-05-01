# sc-ambiences
This repo is a prototypical setup for generating SuperCollider "programs." Originally put together for a sound design project, currently I am interested in building out a pseudo application framework for developing standalone but still interactive SuperCollider processes.
## Dependencies
To be able to interact with the programs in this repository, you need to install SuperCollider first, which is pretty easy to do. Just: 
    1. Go to the SuperCollider [website](https://supercollider.github.io)
    2. Download the latest version of SuperCollider
    3. Install it in your /Applications folder

### Note
So far, this repository is only configured to function with MacOS. I'm going to set it up for Linux too if any one is interested. Windows...not so much. 

## How does it work?

Each of the prototypes actually exist as `.scd` files withni the `src/` directory. Each of these prototypes is associated with a script in the `sc-prototypes` directory, which is set to behave like an executable. As a result, assumging that SuperCollider has been correctly downloaded and installed onto the system, you can interact with each prototype by calling on these scripts; this can be done either by double-clicking on them as if they were an application or by invokving them in the terminal. If you are double-clicking on them, do not be concerned if a new terminal window opens. That is normal. These are bash scripts after all, not actual applications. 

## _new-proto
The exception to this rule is the script called `_new-proto`, which is not part of a prototype but is tasked with generating prototypes. It does this by creating two files: (1) a top-level bash script that runs a `.scd` file using the `sclang` executable installed on the system (only MacOS is supported for now) and (2) the `.scd` file in the `src/` directory. I wrote `_new-proto` so that you can easily contribute your own prototypes if you want. 

## Prototype framework
Not only does the `_new-proto` script generate relevant files for simply running a prototype either from the terminal or by double-clicking, it also creates them in a specific way that allows them to be simple while incorporating shared resources and server configuration options, which can be found in `src/setup.scd`. Therefore, within each pre-configured `.scd` file generated by `_new-proto`, you shoud define all relevant sclang code as the body of a function I have set up called "main." This function is then evaluated in `setup.scd` *after* the configuration has occurred and the server has booted.
