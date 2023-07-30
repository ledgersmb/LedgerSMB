/** @format */

/**
 * OpenAPI tests
 *
 * @group openapi
 */

// Import test packages
import axios from "axios";
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
    axios.defaults.adapter = 'http';
    create_database(username, password, company);

    // Establish API mocking before all tests.
    server.listen({
        onUnhandledRequest: 'bypass'
    });
});

afterAll(() => {
    drop_database(company);
});

// Log in before each test
beforeEach(async () => {
    let r = await axios.post(
        serverUrl + "/login.pl?action=authenticate&company=" + encodeURI(company),
        {
            company: company,
            password: password,
            login: username
        },
        {
            headers: {
                "X-Requested-With": "XMLHttpRequest",
                "Content-Type": "application/json"
            }
        }
    );
    if (r.status === StatusCodes.OK) {
        headers = {
            cookie: r.headers["set-cookie"],
            referer: serverUrl + "/" + r.data.target,
            authorization: "Basic " + btoa(username + ":" + password)
        };
    }
});
// Log out after each test
afterEach(async () => {
    let r = await axios.get(serverUrl + "/login.pl?action=logout&target=_top");
    if (r.status === StatusCodes.OK) {
        headers = {};
    }
});

// Language tests
describe("Retrieving all languages", () => {
    it("GET /languages should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await axios.get(serverUrl + "/" + api + "/languages", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all languages with old syntax should fail", () => {
    it("GET /languages/ should fail", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/languages/", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.BAD_REQUEST
        );
    });
});

describe("Retrieve English language", () => {
    it("GET /language/en should work and satisfy the OpenAPI spec", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/languages/en", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});

describe("Retrieve the French Canadian language", () => {
    it("GET /language/fr_CA", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/languages/fr_CA", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const languageExample = API_yaml.components.examples.validLanguage.value;

        // Assert that the response matches the example in the spec
        expect(res.data).toEqual(languageExample);
    });
});

describe("Retrieve non-existant Navaho language", () => {
    it("GET /languages/nv should not retrieve Navajo language", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/languages/nv", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_FOUND
        );
    });
});

describe("Adding the new Navaho Language", () => {
    it("POST /languages/nv should allow adding Navaho language", async () => {
        let res = await axios.post(
            serverUrl + "/" + api + "/languages",
            {
                code: "nv",
                description: "Navaho"
            },
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});

describe("Modifying the new Navajo language", () => {
    it("PUT /languages/nv should allow updating Navajo language", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/languages/nv", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            serverUrl + "/" + api + "/languages/nv",
            {
                code: "nv",
                description: "Navajo"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});

/*
 * Not implemented yet
describe("Updating the new Navaho language", () => {
    it("PATCH /languages/nv should allow updating Navajo language", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/languages/nv", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            serverUrl + "/" + api + "/languages/nv",
            {
                code: "nv",
                description: "Navaho"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});
*/

describe("Not removing the new Navajo language", () => {
    it("DELETE /languages/nv should allow deleting Navajo language", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/languages/nv", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(serverUrl + "/" + api + "/languages/nv", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.FORBIDDEN
        );
    });
});
