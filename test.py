import tarfile
import os
import shutil

src="/home/autofz/autofz_fuzzbench_test/test2/freetype2-2017_trail2/output/freetype2-2017/afl/afl-master_1/queue"
dst="/home/autofz/test_tar"
timeover=24
def copy_seeds(src:str, dst:str,timeover:int):
    c_time_least=float('inf')
    seed_least=None
    seeds=sorted([seed for seed in os.listdir(src) if seed.startswith("id:")])
    print(len(seeds))
    start_time=os.path.getctime(os.path.join(src,seeds[0]))
    print(start_time,seeds[0])
    seeds=[seed for seed in seeds if (os.path.getctime(os.path.join(src,seed))-start_time<=timeover*60*60)]
    print(len(seeds))
    for seed in seeds:
        shutil.copy(os.path.join(src,seed),dst)
    # for seed in sorted(os.listdir(src)):
    #     if not seed.startswith("id:"):
    #         continue
    #     #print(seed)
    #     #print("mtime ", os.path.getmtime(os.path.join(src,seed))," ctime ", os.path.getctime(os.path.join(src,seed)))
    #     if os.path.getctime(os.path.join(src,seed))<c_time_least:
    #         seed_least=seed
    #         c_time_least=os.path.getctime(os.path.join(src,seed))
    # print(seed_least)
           
copy_seeds(src,dst,timeover)
