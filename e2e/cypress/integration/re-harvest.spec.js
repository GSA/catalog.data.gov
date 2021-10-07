describe('Harvest', () => {
    // Rename this only if necessary, various test dependencies
    const harvestOrg = 'test-harvest-org'
    const wafIsoHarvestSourceName = 'test-harvest-waf-iso'

    before(() => {
        /**
         * Login as cypress user and create an organization for testing harvest source creation and running the jobs
         */
        cy.logout()
        cy.login()
    })
    beforeEach(() => {
        /**
         * Preserve the cookies to stay logged in
         */
        Cypress.Cookies.preserveOnce('auth_tkt', 'ckan')
    })
    after(() => {
        /**
         * Do not clear harvest sources so other tests can
         * evaluate the created datasets
         */
        // cy.delete_harvest_source(wafIsoHarvestSourceName)
        // cy.delete_harvest_source(dataJsonHarvestSoureName)
        // cy.delete_organization(harvestOrg)
    })

    it('Re-harvest WAF ISO', () => {
        cy.start_harvest_job(wafIsoHarvestSourceName)
    });
    
    it('No extras are duplicated (especially harvest)', () => {
        const dataset_name = 'ek500-water-column-sonar-data-collected-during-al0001';
        cy.request(`/api/action/package_show?id=${dataset_name}`).should((response) => {
            expect(response.body).to.have.property('success', true);
            // Harvester should not duplicate harvest info in package
            //  and if there is any duplicate, CKAN validation will fail
            //  in the future.
            let extra_keys = [], duplicate_keys = [];
            for (let extra of response.body.result.extras) {
                if(extra_keys.includes(extra.key)) {
                    duplicate_keys.push(extra.key);
                } else {
                    extra_keys.push(extra.key);
                }
            }
            expect(duplicate_keys).to.be.empty;
        });
    })
})