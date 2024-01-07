FROM python:3.10.12-bullseye

RUN mkdir /app/

COPY . /app/

WORKDIR /app/

RUN pip install flask

EXPOSE 5000

CMD [ "python","web.py" ]