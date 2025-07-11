describe('Dataset', () => {
    // Uses datasets from data.json local harvest to check

    const orgId = "test-organization-dataset";
    const packageId = "dataset-test";
    const title = "Data.gov Statistics Parent";

    before(() => {
      cy.login();
      cy.create_token();
      cy.create_organization(orgId, "Test Organization Dataset");
      cy.create_dataset({
        "name": packageId,
        "title": title,
        "owner_org": orgId,
        "notes": "This is a test dataset created for e2e testing.",
        "extras": [
          {
            "key": "publisher",
            "value": orgId
          },
          {
            "key": "harvest_object_id",
            "value": "object-id"
          },
          {
            "key": "harvest_source_id",
            "value": "source-id"
          },
          {
            "key": "harvest_source_title",
            "value": "source-title"
          }
        ]
      });
      cy.create_resource(packageId, "file:///", "resource-name");
    });

    after(() => {
      // cy.delete_dataset(packageId);
      // cy.delete_organization(orgId);
    });

    it('Has a details page with core metadata', () => {
        cy.visit('/dataset/' + packageId);
        cy.contains(title);
        cy.contains('Additional Metadata');
        cy.contains('Publisher');
        cy.contains('Metadata Source');
        cy.contains('Download Metadata');
        cy.contains('Source Technical Details');
        cy.contains('Harvested from source-title');
        cy.get('#dataset-metadata-source').contains('source-title').click();
        cy.contains('1 dataset found');
    });

    it('Can see resource page', () => {
        cy.visit('/dataset/' + packageId);
        cy.hide_debug_toolbar();
        // Click on the resource link
        cy.contains('resource-name').click();
        cy.contains('About this Resource');
        cy.contains('Visit page');
    });

    it('Can get harvest information via API', () => {
        cy.request(`/api/action/package_show?id=${packageId}`).should((response) => {
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

    it('Can click on items on the sidebar (e.g. org filter)', () => {
        cy.visit('/dataset');
        cy.contains(orgId).click();
        cy.get('div[class="filter-list"] span[class="filtered pill"]').contains(orgId);
    });

    it("Can click on items on the dataset's sidebar (e.g. Publisher )", () => {
        cy.visit('/dataset/' + packageId);
        cy.get('a[title="publisher"]').contains(orgId).click({force: true}); // Publisher was set to orgId
        cy.get('ul[class="dataset-list unstyled"] li').eq(1).click();
        cy.url().should('include', `publisher=${orgId}`);
    });

    it("Can click on feedback button", () => {
        cy.visit('/dataset/' + packageId);
        // sleep for 1 second to allow touchpoint js to load
        cy.wait(1000);
        cy.hide_debug_toolbar();
        // the button is visible
        cy.get('#contact-btn').should('be.visible').click();
        // the modal is invisible
        cy.get('.fba-modal-dialog').should('be.visible');
        cy.get('#fba_location_code').should('have.value', packageId);
        // can hide the modal
        cy.get('.fba-modal-close').click();
        cy.get('.fba-modal-dialog').should('not.be.visible');
    });
});
