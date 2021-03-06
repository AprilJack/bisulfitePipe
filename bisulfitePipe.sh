#!/bin/bash
if [ $# -lt 2 ]
then
        echo "Bisulfite pipe will run bismark in singles mode, extract methylation reports, and make bedGraphs of the methylated/unmethylated tracks"
        echo ""
        echo "Usage: bisulfitePipe bismarkGenomeDir folderWithFastq.gzsOrBAMS"
        echo "To generate bismark genomes run: bismark_genome_preparation"
        echo "Looks like you have the following genomes indexed:"
        ls -d /gpfs/genomes/*.bismark
else
        genome=$1
        shortName=${genome%*.bismark}
        shortName=${shortName##*/}
        dir=$2
        
        if ls *.fastq.gz >/dev/null  2>&1
        then 
          echo "Using genome $shortName located in $genome to process fastq files in $dir"
          for i in ${2}/*fastq.gz ${2}/*fastq
          do
                 echo "Running bismark on $i"
                 bismark $genome $i 
          done
        fi
        
        for i in *.bam
        do
                echo "running methylation extractor on $i"
                bismark_methylation_extractor -s $i --counts --bedGraph --buffer_size 30G --multicore 12 -s --cytosine_report --genome_folder $genome
        done
        for i in *.CpG_report.txt
        do
                makeTagDirectory tags/${i%_bismark.CpG_report.txt} $i -format bismark -minCounts 10 -genome $shortName -checkGC
                makeUCSCfile tags/${i%_bismark.CpG_report.txt} -style methylated -o ${i%_bismark.CpG_report.txt}_m.bedGraph
                makeUCSCfile tags/${i%_bismark.CpG_report.txt} -style unmethylated -o ${i%_bismark.CpG_report.txt}_u.bedGraph
        done
        echo "Finished generating bedGraphs"
fi
