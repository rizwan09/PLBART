#!/usr/bin/env bash

BASE_DIR=/local/username/codebart
HOME_DIR=/home/username/workspace/projects/CodeBART
langs=java,python,en_XX

while getopts ":h" option; do
    case $option in
        h) # display help
            echo
            echo "Syntax: bash run.sh GPU_ID SRC_LANG"
            echo
            echo "SRC_LANG  Language choices: [java, python, go, javascript, php, ruby]"
            echo
            exit;;
    esac
done

export CUDA_VISIBLE_DEVICES=$1

SOURCE=$2
TARGET=en_XX

PRETRAINED_CP_NAME=checkpoint_11_100000.pt

PRETRAIN=${BASE_DIR}/checkpoints/${PRETRAINED_CP_NAME}
PATH_2_DATA=${HOME_DIR}/data/codeXglue/code-to-text/${SOURCE}/data-bin
SPM_MODEL=${BASE_DIR}/sentencepiece.bpe.model


echo "Source: $SOURCE Target: $TARGET"

SAVE_DIR=${BASE_DIR}/code-to-text/${SOURCE}_${TARGET}
mkdir -p ${SAVE_DIR}

if [[ "$SOURCE" =~ ^(ruby|javascript|go|php)$ ]]; then
    USER_DIR="--user-dir /home/username/workspace/projects/CodeBART/src"
    TASK=translation_in_same_language
else
    USER_DIR=""
    TASK=translation_from_pretrained_bart
fi


function fine_tune () {
	OUTPUT_FILE=${SAVE_DIR}/finetune.log
	fairseq-train $PATH_2_DATA $USER_DIR \
		--restore-file $PRETRAIN \
		--bpe 'sentencepiece' --sentencepiece-model $SPM_MODEL \
  		--langs $langs --arch mbart_base --layernorm-embedding \
  		--task $TASK --source-lang $SOURCE --target-lang $TARGET \
  		--criterion label_smoothed_cross_entropy --label-smoothing 0.2 \
  		--batch-size 8 --update-freq 4 --max-epoch 15 \
  		--optimizer adam --adam-eps 1e-06 --adam-betas '(0.9, 0.98)' \
  		--lr-scheduler polynomial_decay --lr 5e-05 --min-lr -1 \
  		--warmup-updates 1000 --max-update 200000 \
  		--dropout 0.1 --attention-dropout 0.1 --weight-decay 0.0 \
  		--seed 1234 --log-format json --log-interval 100 \
  		--reset-optimizer --reset-meters --reset-dataloader --reset-lr-scheduler \
		--eval-bleu --eval-bleu-detok space --eval-tokenized-bleu \
  		--eval-bleu-remove-bpe sentencepiece --eval-bleu-args '{"beam": 5}' \
  		--best-checkpoint-metric bleu --maximize-best-checkpoint-metric \
  		--eval-bleu-print-samples --no-epoch-checkpoints --patience 5 \
  		--ddp-backend no_c10d --save-dir $SAVE_DIR 2>&1 | tee ${OUTPUT_FILE}
}


function generate () {
	model=${SAVE_DIR}/checkpoint_best.pt
	FILE_PREF=${SAVE_DIR}/output
	RESULT_FILE=${SAVE_DIR}/result.txt

	fairseq-generate $PATH_2_DATA $USER_DIR \
 		--path $model \
  		--task $TASK \
  		--gen-subset test \
  		-t $TARGET -s $SOURCE \
  		--sacrebleu --remove-bpe 'sentencepiece' \
  		--batch-size 4 --langs $langs --beam 10 > $FILE_PREF

	cat $FILE_PREF | grep -P "^H" |sort -V |cut -f 3- | sed 's/\[${TARGET}\]//g' > $FILE_PREF.hyp
	cat $FILE_PREF | grep -P "^T" |sort -V |cut -f 2- | sed 's/\[${TARGET}\]//g' > $FILE_PREF.ref
	sacrebleu -tok 'none' -s 'none' $FILE_PREF.ref < $FILE_PREF.hyp 2>&1 | tee ${RESULT_FILE}
	printf "CodeXGlue Evaluation: \t" >> ${RESULT_FILE}
	python evaluator.py $FILE_PREF.ref $FILE_PREF.hyp >> ${RESULT_FILE}
	python evaluator.py $FILE_PREF.ref $FILE_PREF.hyp;
}


fine_tune
generate
