FROM tensorflow/tensorflow:nightly

WORKDIR /

RUN apt-get update
RUN apt-get install -y git
RUN	pip install tensorflow==1.8.0
RUN	pip install tensorflow_hub==0.1.0
RUN mkdir /retrain

COPY retrain.py /retrain/.
WORKDIR /retrain
RUN mkdir /data

ENTRYPOINT ["python", "retrain.py"]
