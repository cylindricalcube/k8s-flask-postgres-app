FROM python:3.8

WORKDIR /tmp

COPY src/requirements.txt .

RUN pip install -r requirements.txt

WORKDIR /opt/todoozle

ADD todoozle.tar.gz .

ENTRYPOINT ["python"]

CMD ["todoozle.py"]