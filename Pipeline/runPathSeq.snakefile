## unalign and run pathseq on samples

"""
#before running snakemake, do in tmux terminal:
ml snakemake/5.19.2-foss-2019b-Python-3.7.4
ml BWA/0.7.17-GCC-8.3.0
ml picard/2.18.29-Java
#ml Java/11.0.2
ml Java/1.8.0_181
#ml GATK/4.1.8.1-GCCcore-8.3.0-Java-11
ml GATK/4.1.3.0-GCCcore-8.3.0-Java-1.8


#command to run snakemake (remove -np at end when done validating):
snakemake -s runPathSeq.snakefile --latency-wait 60 --keep-going --cluster-config config/cluster_slurm.yaml --cluster "sbatch -p {cluster.partition} --mem={cluster.mem} -t {cluster.time} -c {cluster.ncpus} -n {cluster.ntasks} -o {cluster.output}" -j 40 -np
"""

configfile: "config/config.yaml"
configfile: "config/samples.yaml"

rule all:
    input:
        expand("results/unaligned/{samples}.bam", samples=config["samples"]),
        expand("results/pathseq/{samples}.bam", samples=config["samples"])


rule unalign:
    input:
        bam_file = lambda wildcards: config["samples"][wildcards.samples],
    output:
        "results/unaligned/{samples}.bam"
    params:
        java=config["java"],
        picard_jar = config["picard_jar"], 
        ref = config["ref"]
    log:
        "logs/unaligned/{samples}.log"
    shell:
        "{params.java} -Xmx100G -jar {params.picard_jar} RevertSam \
            I={input.bam_file} \
            O={output} \
            SANITIZE=true \
            MAX_DISCARD_FRACTION=0.005 \
            ATTRIBUTE_TO_CLEAR=XT \
            ATTRIBUTE_TO_CLEAR=XN \
            ATTRIBUTE_TO_CLEAR=AS \
            ATTRIBUTE_TO_CLEAR=OC \
            ATTRIBUTE_TO_CLEAR=OP \
            SORT_ORDER=queryname \
            RESTORE_ORIGINAL_QUALITIES=true \
            REMOVE_DUPLICATE_INFORMATION=true \
            REMOVE_ALIGNMENT_INFORMATION=true \
            R={params.ref} \
            VALIDATION_STRINGENCY=LENIENT"

rule pathseq:
    input:
        bam_file = "results/unaligned/{samples}.bam"
    output:
        "results/pathseq/{samples}.bam"
    params:
        java=config["java"],
        gatk_jar = config["gatk_jar"],
        filter_bwa_image = config["filter_bwa_image"],
        kmer_file = config["kmer_file"],
        min_clipped_read_length = config["min_clipped_read_length"],
        microbe_fasta = config["microbe_fasta"],
        microbe_bwa_image = config["microbe_bwa_image"],
        taxonomy_file = config["taxonomy_file"],
        ref = config["ref"]
    log:
        "logs/pathseq/{samples}.log"
    shell:
        "{params.java} -Xmx100G -jar {params.gatk_jar} PathSeqPipelineSpark \
            --input {input.bam_file} \
            --filter-bwa-image {params.filter_bwa_image} \
            --kmer-file {params.kmer_file} \
            --min-clipped-read-length {params.min_clipped_read_length} \
            --microbe-fasta {params.microbe_fasta} \
            --microbe-bwa-image {params.microbe_bwa_image} \
            --taxonomy-file {params.taxonomy_file} \
            --output {output} \
            --scores-output {output}.txt"
