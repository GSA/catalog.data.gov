describe('Harvest', () => {
    // Rename this only if necessary, various test dependencies
    const harvestOrg = 'test-harvest-org';
    const wafIsoHarvestSourceName = 'test-harvest-waf-iso';
    const dataJsonHarvestSoureName = 'test-harvest-datajson';

    before(() => {
        cy.login();
    });

    beforeEach(() => {
        /**
         * Preserve the cookies to stay logged in
         */
        Cypress.Cookies.preserveOnce('auth_tkt', 'ckan');
    });

    after(() => {
        cy.logout();
    });

    it('Re-harvest WAF ISO', () => {
        cy.start_harvest_job(wafIsoHarvestSourceName);
    });

    it('No extras are duplicated (especially harvest)', () => {
        const dataset_name = 'ek500-water-column-sonar-data-collected-during-al0001';
        cy.request(`/api/action/package_show?id=${dataset_name}`).should((response) => {
            expect(response.body).to.have.property('success', true);
            // Harvester should not duplicate harvest info in package
            //  and if there is any duplicate, CKAN validation will fail
            //  in the future.
            let extra_keys = [],
                duplicate_keys = [];
            for (let extra of response.body.result.extras) {
                if (extra_keys.includes(extra.key)) {
                    duplicate_keys.push(extra.key);
                } else {
                    extra_keys.push(extra.key);
                }
            }
            expect(duplicate_keys).to.be.empty;
        });
    });

    it('Re-harvest data json', () => {
        cy.start_harvest_job(dataJsonHarvestSoureName);
    });

    it('No datasets are duplicated in datajson', () => {
        const dataset_title = '2015 GSA Common Baseline Implementation Plan and CIO Assignment Plan';
        cy.request(`/api/action/package_search?q=title:"${dataset_title}"`).should((response) => {
            expect(response.body.result.count).to.equal(1)
        })
    })
});
