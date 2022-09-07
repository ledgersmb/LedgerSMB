/** @format */

/**
 * OpenAPI tests
 *
 * @group openapi
 */

// Import test packages
import axios from "axios";
import http from "axios/lib/adapters/http";
import jestOpenAPI from "jest-openapi";
import { StatusCodes } from "http-status-codes";
import { create_database, drop_database } from "./database";

// Load an OpenAPI file (YAML or JSON) into this plugin
jestOpenAPI(process.env.PWD + "/openapi/API.yaml");

// Set API version to use
const api = "erp/api/v0";

// Access to the database test user

const id = Math.random().toString(36).substr(2, 6);

const username = `Jest${id}`;
const password = "Tester";
const company = `lsmb_test_api_${id}`;

const server = process.env.LSMB_BASE_URL;

let headers = {};

// For all tests
beforeAll(() => {
    axios.defaults.adapter = http;
    create_database(username, password, company);
});

afterAll(() => {
    drop_database(company);
});

// Log in before each test
beforeEach(async () => {
    let r = await axios.post(
        server + "/login.pl?action=authenticate&company=" + encodeURI(company),
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
            referer: server + "/" + r.data.target,
            authorization: "Basic " + btoa(username + ":" + password)
        };
    }
});
// Log out after each test
afterEach(async () => {
    let r = await axios.get(server + "/login.pl?action=logout&target=_top");
    if (r.status === StatusCodes.OK) {
        headers = {};
    }
});

// GIFI tests
describe("Retrieving all gifis", () => {
    it("GET /gifi should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your server
        let res = await axios.get(server + "/" + api + "/gl/gifi", {
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
            axios.get(server + "/" + api + "/gl/gifi/", {
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
            axios.get(server + "/" + api + "/gl/gifi/99999", {
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
            server + "/" + api + "/gl/gifi",
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

describe("Modifying the new GIFI 99999", () => {
    it("PUT /gifi/99999 should allow updating Test GIFI", async () => {
        let res = await axios.get(server + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            server + "/" + api + "/gl/gifi/99999",
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
        let res = await axios.get(server + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            server + "/" + api + "/gl/gifi/99999",
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
        let res = await axios.get(server + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(server + "/" + api + "/gl/gifi/99999", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.FORBIDDEN
        );
    });
});
