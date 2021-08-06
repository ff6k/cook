interface HttpResponse<T> extends Response {
  parsedBody?: T;
}

export async function http<T>(
  request: RequestInfo
): Promise<HttpResponse<T>> {
  const response: HttpResponse<T> = await fetch(
    request
  );
  response.parsedBody = await response.json();
  return response;
}

// example consuming code
// const response = await http<Todo[]>(
//   "https://jsonplaceholder.typicode.com/todos"
// );
