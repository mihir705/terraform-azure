import azure.functions as func

app = func.FunctionApp()


@app.route(route="hello", auth_level=func.AuthLevel.ANONYMOUS)
def hello(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse("Hello from mihir prod")
