/** @format */

// Import test packages
import jestOpenAPI from "jest-openapi";
import { StatusCodes } from "http-status-codes";
import { create_database, drop_database } from "./database";
import { server } from '../../common/mocks/server.js'

// Load an OpenAPI file (YAML or JSON) into this plugin
const openapi = process.env.PWD.replace("/UI","");
jestOpenAPI( openapi + "/openapi/API.yaml");

// Load the API definition
const API_yaml = require (openapi + "/openapi/API.yaml");

// Set API version to use
const api = "erp/api/v0";

// Access to the database test user

const id = Math.random().toString(36).substr(2, 6);

const username = `Jest${id}`;
const password = "Tester";
const company = `lsmb_test_api_${id}`;

const serverUrl = process.env.LSMB_BASE_URL;

let headers = {};

// For all tests
beforeAll(() => {
    create_database(username, password, company);

    // Establish API mocking before all tests.
    server.listen({
        onUnhandledRequest: 'bypass'
    });
});

afterAll(() => {
    drop_database(company);
});

const emulateAxiosResponse = async(res) => {
    return {
        data: await res.json(),
        status: res.status,
        statusText: res.statusText,
        headers: res.headers,
        request: {
            path: res.url,
            method: 'GET'
        }
    };
};

// Log in before each test
beforeEach(async () => {
    let r = await fetch(
        serverUrl + "/login.pl?action=authenticate&company=" + encodeURI(company),
        {
            method: "POST",
            body: JSON.stringify({
                company: company,
                password: password,
                login: username
            }),
            headers: {
                "X-Requested-With": "XMLHttpRequest",
                "Content-Type": "application/json"
            }
        }
    );
    if (r.status === StatusCodes.OK) {
        const data = await r.json();
        headers = {
            cookie: r.headers.get("set-cookie"),
            referer: serverUrl + "/" + data.target,
            authorization: "Basic " + btoa(username + ":" + password)
        };
    }
});

// Log out after each test
afterEach(async () => {
    let r = await fetch(serverUrl + "/login.pl?action=logout&target=_top");
    if (r.status === StatusCodes.OK) {
        headers = {};
    }
});

// Language tests
describe("Retrieving all languages", () => {
    it("GET /languages should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await fetch(serverUrl + "/" + api + "/languages", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all languages with old syntax should fail", () => {
    it("GET /languages/ should fail", async () => {
        let res = await fetch(serverUrl + "/" + api + "/languages/", {
                headers: headers
        });
        expect(res.status).toEqual(StatusCodes.BAD_REQUEST);
    });
});

describe("Retrieve English language", () => {
    it("GET /language/en should work and satisfy the OpenAPI spec", async () => {
        let res = await fetch(serverUrl + "/" + api + "/languages/en", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});

describe("Retrieve the French Canadian language", () => {
    it("GET /language/fr_CA", async () => {
        let res = await fetch(serverUrl + "/" + api + "/languages/fr_CA", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const languageExample = API_yaml.components.examples.validLanguage.value;

        // Assert that the response matches the example in the spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toEqual(languageExample);
    });
});

describe("Retrieve non-existant Navaho language", () => {
    it("GET /languages/nv should not retrieve Navajo language", async () => {
        let res = await fetch(serverUrl + "/" + api + "/languages/nv", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_FOUND);
    });
});

describe("Adding the new Navaho Language", () => {
    it("POST /languages/nv should allow adding Navaho language", async () => {
        let res = await fetch(serverUrl + "/" + api + "/languages", {
            method: "POST",
            body: JSON.stringify({
                code: "nv",
                description: "Navaho"
            }),
            headers: { ...headers, "Content-Type": "application/json" }
        });
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});

describe("Modifying the new Navajo language", () => {
    it("PUT /languages/nv should allow updating Navajo language", async () => {
        let res = await fetch(serverUrl + "/" + api + "/languages/nv", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(serverUrl + "/" + api + "/languages/nv", {
            method: "PUT",
            body: JSON.stringify({
                code: "nv",
                description: "Navajo",
                default: true
            }),
            headers: {
                ...headers,
                "Content-Type": "application/json",
                "If-Match": etag
            }
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});

/*
 * Not implemented yet
describe("Updating the new Navaho language", () => {
    it("PATCH /languages/nv should allow updating Navajo language", async () => {
        let res = await fetch(serverUrl + "/" + api + "/languages/nv", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(serverUrl + "/" + api + "/languages/nv", {
            method: "PATCH",
            body: JSON.stringify({
                code: "nv",
                description: "Navaho"
            }),
            headers: {
                ...headers,
                "Content-Type": "application/json",
                "If-Match": etag
            }
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});
*/

describe("Not removing the new Navajo language", () => {
    it("DELETE /languages/nv should allow deleting Navajo language", async () => {
        let res = await fetch(serverUrl + "/" + api + "/languages/nv", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();

        res = await fetch(serverUrl + "/" + api + "/languages/nv", {
            method: "DELETE",
            headers: { ...headers, "If-Match": etag }
        });
        expect(res.status).toEqual(StatusCodes.FORBIDDEN);
    });
});
