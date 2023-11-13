import os
import argparse
from loguru import logger
from typing import List


supported_targets=["freetype2-2017","lcms-2017-03-21","vorbis-2017-12-11","woff2-2016-05-06"]
supported_fuzzers=["afl","aflfast","redqueen","lafintel","fairfuzz","mopt"]

def main():
    parser=argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest=argparse.SUPPRESS, required=True)

    parser_launch=subparsers.add_parser("launch", help="Launch experiment")
    parser_launch.add_argument("-e","--experiment_name", required=True,help="Experiment name")
    parser_launch.add_argument("-t","--fuzz_target", nargs="+", choices=supported_targets, default=supported_targets, help="Fuzz targets")
    parser_launch.add_argument("-f","--fuzzer", nargs="+", choices=supported_fuzzers, default=supported_fuzzers, help="Fuzzer")
    parser_launch.add_argument("-tn","--trail_number", nargs="+", type=int, default=3, help="Trail number")
    parser_launch.set_defaults(func=launch)

    parser_report=subparsers.add_parser("report", help="Generate experiment report")
    parser_report.add_argument("-e","--experiment_name", required=True,help="Experiment name")
    parser_report.add_argument("-t","--fuzz_target", nargs="+", choices=supported_targets, default=supported_targets, help="Fuzz targets")
    parser_report.set_defaults(func=report)   
    
    args=parser.parse_args()
    if(args.fuzz_target):
        args.fuzz_target=list(set(args.fuzz_target))
    dict_args = vars(args)
    func = dict_args.pop("func")
    func(**dict_args)



def launch(experiment_name: str, fuzzer: List[str], fuzz_target: List[str],trail_number:int):
    logger.info(f"Launching experiment {experiment_name}")
    logger.info(f"Fuzzers: {fuzzer}")
    try:
        os.makedirs(experiment_name)
    except Exception as e:
        logger.error(e)
        return
    logger.info(f"Fuzz targets: {fuzz_target}")
    if trail_number<=0:
        logger.error("Trail num should be greater than 0.")
        return
    current_directory = os.getcwd()
    for trail in range(trail_number):
        for fz_target in fuzz_target:
            trail_folder=os.path.join(experiment_name,fz_target+"_trail"+str(trail))
            os.makedirs(trail_folder)
            os.chdir(trail_folder)
            cmd_launch= f"docker run --cpus=1 -d --rm --privileged -v $PWD:/work/autofz -w /work/autofz \
-it autofz /bin/bash -c \"sudo /init.sh && autofz -o output -T 24h -f {' '.join(map(str, fuzzer))} -t {fz_target}\""
            logger.info(cmd_launch)
            os.system(cmd_launch)
            os.chdir(current_directory)





    

def report(experiment_name: str, fuzz_target: List[str]):
    logger.info(f"Generating report for experiment {experiment_name}")
    logger.info(f"Fuzz targets: {fuzz_target}")


if __name__=="__main__":
    main()

