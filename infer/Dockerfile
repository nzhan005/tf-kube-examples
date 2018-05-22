FROM tensorflow/tensorflow:nightly

WORKDIR /

RUN apt-get update
RUN apt-get install -y git
RUN	pip install tensorflow==1.8.0
RUN mkdir /infer

COPY infer.py /infer/.
WORKDIR /infer
RUN mkdir /data

ENTRYPOINT ["python", "infer.py"]
