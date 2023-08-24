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

// GIFI tests
describe("Retrieving all gifis", () => {
    it("GET /gifi should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await axios.get(serverUrl + "/" + api + "/gl/gifi", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all gifis with old syntax should fail", () => {
    it("GET /gifi/ should fail", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/gl/gifi/", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.BAD_REQUEST
        );
    });
});

describe("Retrieve non-existant GIFI 99999", () => {
    it("GET /gifi/99999 should not retrieve invalid GIFI", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/gl/gifi/99999", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_FOUND
        );
    });
});

describe("Adding the new Test GIFI", () => {
    it("POST /gifi/99999 should allow adding a new GIFI", async () => {
        let res = await axios.post(
            serverUrl + "/" + api + "/gl/gifi",
            {
                accno: "99999",
                description: "Test GIFI"
            },
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("GIFI");
    });
});

describe("Validate against the example GIFI 99999", () => {
    it("GET /gifi/99999 should validate our new GIFI", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const gifiExample = API_yaml.components.examples.validGIFI.value;

        // Assert that the response matches the example in the spec
        expect(res.data).toEqual(gifiExample);
    });
});

describe("Modifying the new GIFI 99999", () => {
    it("PUT /gifi/99999 should allow updating Test GIFI", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            serverUrl + "/" + api + "/gl/gifi/99999",
            {
                accno: "99999",
                description: "Test GIFI"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("GIFI");
    });
});

/*
 * Not implemented yet
describe("Updating the new GIFI 99999", () => {
    it("PATCH /gifi/99999 should allow updating Test GIFI", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            serverUrl + "/" + api + "/gl/gifi/99999",
            {
                accno: "99999",
                description: "Test GIFI"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("GIFI");
    });
});
*/

describe("Not Removing the new GIFI 99999", () => {
    it("DELETE /gifi/99999 should allow deleting Test GIFI", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(serverUrl + "/" + api + "/gl/gifi/99999", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.FORBIDDEN
        );
    });
});
