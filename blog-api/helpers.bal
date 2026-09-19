// Small helpers shared by every resource in service.bal: turning a refusal
// into the contract's Error envelope, validating input, and paginating a
// collection response.

function unauthorizedError() returns ErrorUnauthorized => {
    body: {code: 401, message: "Not signed in"}
};

function notFoundError(string message) returns ErrorNotFound => {
    body: {code: 404, message}
};

function badRequestError(string message) returns ErrorBadRequest => {
    body: {code: 400, message}
};

function validPostInput(PostInput payload) returns boolean {
    return payload.title.trim() != "" && payload.body.trim() != "";
}

function clampLimit(int requested) returns int {
    if requested < 1 {
        return 20;
    }
    if requested > 100 {
        return 100;
    }
    return requested;
}

function clampOffset(int requested) returns int {
    return requested < 0 ? 0 : requested;
}

function nextUri(string basePath, int pageLimit, int pageOffset, int total) returns string? {
    int nextOffset = pageOffset + pageLimit;
    if nextOffset >= total {
        return ();
    }
    return string `${basePath}?limit=${pageLimit}&offset=${nextOffset}`;
}

function previousUri(string basePath, int pageLimit, int pageOffset) returns string? {
    if pageOffset <= 0 {
        return ();
    }
    int previousOffset = pageOffset - pageLimit;
    if previousOffset < 0 {
        previousOffset = 0;
    }
    return string `${basePath}?limit=${pageLimit}&offset=${previousOffset}`;
}
