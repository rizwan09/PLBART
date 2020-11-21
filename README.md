# PLBART
Code pre-release of our work on "Unified Pre-training for Program Understanding and Generation".

### Pre-training data

PLBART is pre-trained on Java and Python functions and natural language descriptions collected from Github and StackOverflow.


### Evaluation tasks

We evaluated PLBART on five tasks.

- Code summarization [[info](https://github.com/microsoft/CodeXGLUE/tree/main/Code-Text/code-to-text#dataset)]
- Code generation [[info](https://github.com/microsoft/CodeXGLUE/tree/main/Text-Code/text-to-code#task-definition)]
- Code translation [[info](https://github.com/microsoft/CodeXGLUE/tree/main/Code-Code/code-to-code-trans#task-definition)]
- Clone detection [[info](https://github.com/microsoft/CodeXGLUE/tree/main/Code-Code/Clone-detection-BigCloneBench#task-definition)]
- Vulnerability detection [[info](https://github.com/microsoft/CodeXGLUE/tree/main/Code-Code/Defect-detection#codexglue----defect-detection)]


### Notes

- We will publish the pretrained PLBART checkpoint upon acceptance of our paper.
- We list all the files in this repository [here](https://github.com/plbart-2020/PLBART/blob/main/FILEs.md).



### Acknowledgement

PLBART uses [Fairseq](https://github.com/pytorch/fairseq), [codeXglue](https://github.com/microsoft/CodeXGLUE), and [TransCoder](https://github.com/facebookresearch/TransCoder) and thanks the authors of these works for their contribution.
