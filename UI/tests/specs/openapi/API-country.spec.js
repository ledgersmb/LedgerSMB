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

// COUNTRY tests
describe("Retrieving all countries", () => {
    it("GET /countries should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await axios.get(serverUrl + "/" + api + "/countries", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all countries with old syntax should fail", () => {
    it("GET /countries/ should fail", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/countries/", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.BAD_REQUEST
        );
    });
});

describe("Validate against the example country", () => {
    it("GET /countries/NL", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/countries/NL", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const countryExample = API_yaml.components.examples.validCountry.value;

        // Assert that the response matches the example in the spec
        expect(res.data).toEqual(countryExample);
    });
});

describe("Retrieve non-existant COUNTRY ZZ should fail", () => {
    it("GET /countries/ZZ should not retrieve invalid COUNTRY", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/countries/ZZ", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_FOUND
        );
    });
});

describe("Adding the new Test COUNTRY ZZ", () => {
    it("POST /countries/ZZ should allow adding a new COUNTRY", async () => {
        let res = await axios.post(
            serverUrl + "/" + api + "/countries",
            {
                code: "ZZ",
                name: "Atlantika"
            },
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Country");
    });
});

describe("Modifying the new COUNTRY ZZ", () => {
    it("PUT /countries/ZZ should allow modifying Atlantica", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/countries/ZZ", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            serverUrl + "/" + api + "/countries/ZZ",
            {
                code: "ZZ",
                name: "Atlantica"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Country");
    });
});

/*
Not implemented yet
describe("Updating the new COUNTRY ZZ", () => {
    it("PATCH /countries/ZZ should allow updating Atlantica", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/countries/ZZ", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            serverUrl + "/" + api + "/countries/ZZ",
            {
                code: "ZZ",
                name: "Atlantika"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("COUNTRY");
    });
});
*/

describe("Not Removing COUNTRY ZZ", () => {
    it("DELETE /countries/ZZ should not allow deleting Test COUNTRY", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/countries/ZZ", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(serverUrl + "/" + api + "/countries/ZZ", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.FORBIDDEN
        );
    });
});
