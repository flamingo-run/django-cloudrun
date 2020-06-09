from celery import Celery

app = Celery('django-cloudrun')
app.conf.broker_backend = 'memory'
app.conf.task_always_eager = True
app.conf.task_eager_propagates = True
app.autodiscover_tasks()
