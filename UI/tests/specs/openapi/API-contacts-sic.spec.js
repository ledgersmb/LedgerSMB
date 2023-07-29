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

// Contact SIC tests
describe("Retrieving all SIC", () => {
    it("GET /contacts/sic should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await axios.get(serverUrl + "/" + api + "/contacts/sic", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all SIC with old syntax should fail", () => {
    it("GET /contacts/sic/ should fail", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/contacts/sic/", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.BAD_REQUEST
        );
    });
});

describe("Retrieve non-existant SIC", () => {
    it("GET /contacts/sic/541510 should not retrieve our SIC", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/contacts/sic/541510", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_FOUND
        );
    });
});

describe("Adding the IT SIC", () => {
    it("POST /contacts/sic/541510 should allow adding IT SIC", async () => {
        let res = await axios.post(
            serverUrl + "/" + api + "/contacts/sic",
            {
                code: "541510",
                description: "Design of computer systems"
            },
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("SIC");
    });
});

describe("Validate against the example SIC", () => {
    it("GET /contacts/sic/541510 should validate IT SIC", async () => {
        let res = await axios.get(
            serverUrl + "/" + api + "/contacts/sic/541510",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const sicExample = API_yaml.components.examples.validSIC.value;

        // Assert that the response matches the example in the spec
        expect(res.data).toEqual(sicExample);
    });
});

describe("Modifying the new IT SIC", () => {
    it("PUT /contacts/sic/541510 should allow updating IT SIC", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/contacts/sic/541510", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            serverUrl + "/" + api + "/contacts/sic/541510",
            {
                code: "541510",
                description: "Design of computer systems and related services"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("SIC");
    });
});

/*
 * Not implemented yet
describe("Updating the new IT SIC", () => {
    it("PATCH /contacts/sic/541510 should allow updating IT SIC", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/contacts/sic/541510", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            serverUrl + "/" + api + "/contacts/sic/541510",
            {
                code: "541510",
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
        expect(res.data).toSatisfySchemaInApiSpec("SIC");
    });
});
*/

describe("Not removing the new IT SIC", () => {
    it("DELETE /contacts/sic/541510 should allow deleting IT SIC", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/contacts/sic/541510", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(serverUrl + "/" + api + "/contacts/sic/541510", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.FORBIDDEN
        );
    });
});
