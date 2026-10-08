~~~ python
def factorial(n):
    """Devuelve el factorial de n, para cualquier ↩
    entero no negativo."""
    if n <= 1:
        return 1
    return n * factorial(n - 1)
~~~
