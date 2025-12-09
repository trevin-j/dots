#!/bin/env python3
import random

transition_types = [
    {
        "type": "fade",
    },
    {
        "type": "wipe",
        "opts": [
            ("--transition-angle", random.randrange(0, 360)),
        ],
    },
    {
        "type": "wave",
        "opts": [
            ("--transition-angle", random.randrange(360)),
            ("--transition-wave", random.randint(5, 50), random.randint(5, 50)),
        ],
    },
    {
        "type": "grow",
        "opts": [
            ("--transition-pos", random.random(), random.random())
        ],
    },
    {
        "type": "outer",
        "opts": [
            ("--transition-pos", random.random(), random.random())
        ],
    },
]

def get_args(index: int) -> str:
    transition = transition_types[index]
    t_type = transition["type"]
    if not "opts" in transition.keys():
        return f"--transition-type {t_type}"
    t_opts = transition["opts"]
    t_opt_str = ""
    for opt in t_opts:
        t_opt_str += f"{opt[0]} {','.join([str(o) for o in opt[1:]])} "
    return f"--transition-type {t_type} {t_opt_str}"

def main():
    print(get_args(random.randrange(len(transition_types))))

if __name__ == "__main__":
    main()
