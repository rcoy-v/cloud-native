const expect = require('chai').expect;
const sinon = require('sinon');
const chance = require('chance').Chance();

const handler = require('./handler');

describe('handler', async () => {
    let contextStub, dateNowStub, expectedTimestamp;

    beforeEach(() => {
        contextStub = {
            status: sinon.stub().returnsThis(),
            succeed: sinon.stub().returnsThis(),
        };

        expectedTimestamp = chance.timestamp();
        dateNowStub = sinon.stub(Date, 'now');
        dateNowStub.returns(expectedTimestamp);
    });

    afterEach(() => {
        sinon.restore();
    });

    it('should return the context', async () => {
        const result = await handler({}, contextStub);

        expect(result).equal(contextStub);
    });

    it('should contain a message', async () => {
        await handler({}, contextStub);

        const message = contextStub.succeed.getCall(0).args[0].message;

        expect(message).equal('Automate all the things!');
    });

    it('should contain the current timestamp', async () => {
        await handler({}, contextStub);

        const timestamp = contextStub.succeed.getCall(0).args[0].timestamp;

        expect(timestamp).equal(expectedTimestamp);
    });

    it('should have an ok status', async () => {
        await handler({}, contextStub);

        const status = contextStub.status.getCall(0).args[0];

        expect(status).equal(200);
    });
});
