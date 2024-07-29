describe('Dataset', () => {
    // Uses datasets from data.json local harvest to check

    it('Has a details page with core metadata', () => {
        cy.visit('/dataset/data-gov-statistics-parent');
        cy.contains('Data.gov Statistics Parent');
        cy.contains('Metadata Source');
        cy.contains('Additional Metadata');
        cy.contains('Identifier');
        cy.contains('Publisher');
        cy.contains('Bureau Code');
    });

    it('Can see resource pages', () => {
        cy.visit('/dataset/2015-gsa-common-baseline-implementation-plan-and-cio-assignment-plan');
        cy.hide_debug_toolbar();
        // Click on the resource link
        cy.contains('2015 GSA Common Baseline Implementation Plan...').click();
        cy.contains('About this Resource');
        cy.contains('Download');
    });

    it('Can get harvest information via API', () => {
        cy.request('/api/action/package_show?id=ek500-water-column-sonar-data-collected-during-al0001').should((response) => {
            expect(response.body).to.have.property('success', true);
            // CKAN extras are complicated to parse, make sure we have
            //  the necessary harvest info
            let harvest_info = {};
            for (let extra of response.body.result.extras) {
                if (extra.key.includes('harvest_')) {
                    harvest_info[extra.key] = true;
                }
            }
            expect(harvest_info).to.have.property('harvest_object_id', true);
            expect(harvest_info).to.have.property('harvest_source_id', true);
            expect(harvest_info).to.have.property('harvest_source_title', true);
        });
    });

    it('Can click on items on the sidebar (e.g. tags filter)', () => {
        cy.visit('/dataset');
        cy.contains('test-harvest-org').click();
        cy.get('div[class="filter-list"] span[class="filtered pill"]').contains('test-harvest-org');
    });

    it('Can click on Show More Tags on the sidebar (e.g. tags filter)', () => {
        cy.visit('/dataset');
        cy.contains('Show More Tags').click();
        cy.url().should('include', '?_tags_limit=0');
    });

    it("Can click on items on the dataset's sidebar (e.g. )", () => {
        cy.visit('/dataset/ek500-water-column-sonar-data-collected-during-al0001');
        cy.get('a[class="heading"]').contains('NCEI Contact Information').click();
        cy.get('ul[class="list-unstyled nav nav-simple"] li').eq(1).click();
    });

    it("Can click on feedback button", () => {
        cy.visit('/dataset/ek500-water-column-sonar-data-collected-during-al0001');
        // sleep for 1 second to allow touchpoint js to load
        cy.wait(1000);
        cy.hide_debug_toolbar();
        // the button is visible
        cy.get('#contact-btn').should('be.visible').click();
        // // the modal is invisible
        // cy.get('#fba-modal-dialog').should('be.visible');
        // cy.get('#fba_location_code').should('have.value', 'ek500-water-column-sonar-data-collected-during-al0001');
        // // can hide the modal
        // cy.get('a[class="fba-modal-close"]').click();
        // cy.get('#fba-modal-dialog').should('not.be.visible');
    });
});
