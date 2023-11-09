import os
import argparse
from loguru import logger
from typing import List


supported_targets=["freetype","libpng","libjpeg","openssl"]

def main():
    parser=argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest=argparse.SUPPRESS, required=True)

    parser_launch=subparsers.add_parser("launch", help="Launch experiment")
    parser_launch.add_argument("-e","--experiment_name", required=True,help="Experiment name")
    parser_launch.add_argument("-t","--fuzz_target", nargs="+", choices=supported_targets, default=supported_targets, help="Fuzz targets")
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



def launch(experiment_name: str, fuzz_target: List[str]):
    logger.info(f"Launching experiment {experiment_name}")
    try:
        os.makedirs(experiment_name)
    except Exception as e:
        print(e)
        return
    logger.info(f"Fuzz targets: {fuzz_target}")
    

def report(experiment_name: str, fuzz_target: List[str]):
    logger.info(f"Generating report for experiment {experiment_name}")
    logger.info(f"Fuzz targets: {fuzz_target}")


if __name__=="__main__":
    main()

