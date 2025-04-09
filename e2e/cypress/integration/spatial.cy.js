describe('Spatial', () => {
    before(() => {
        cy.login();
        cy.create_token();
    });

    after(() => {
        cy.revoke_token();
        cy.logout();
    });

    it('Can search geographies by name', () => {
        cy.request('/api/3/action/location_search?q=california').should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result[0]).to.have.property('text', 'California');
        });
    });

    it('The map view works and can draw box and search', () => {

        let orgId = `org-${cy.helpers.randomSlug()}`;
        cy.create_organization(orgId);
        let packageId = `package-${orgId}`;
        cy.create_dataset({
          "name": packageId,
          "owner_org": orgId,
          "extras": [
            {
              // stole this GeoJSON from an actual dataset
              "key": "spatial",
              "value": '{"type": "Polygon", "coordinates": [[[-96.8600, 43.4600], [-96.8600, 43.6500], [-96.5800, 43.6500], [-96.5800, 43.4600], [-96.8600, 43.4600]]]}'
            }
          ]
        });

        cy.visit('/dataset');
        cy.get('.leaflet-control-custom-button').click();
        cy.get('.modal-spatial-query .modal-footer').find('.disabled');
        cy.get('#draw-map-container')
            .trigger('mousedown', { which: 1 })
            .trigger('mousemove', { clientX: 600, clientY: 153 }) // this happens to intersect the above polygon
            .trigger('mouseup');
        cy.hide_debug_toolbar();
        // click the apply button then on the next redirected page find the box
        // on the map and content in the body
        cy.get('.modal-spatial-query .modal-footer').find('[class="btn btn-primary apply"]').click();
        cy.get('#dataset-map-container').find('svg.leaflet-zoom-animated');
        cy.contains(/1 dataset found/);

        cy.delete_dataset(packageId);
        cy.delete_organization(orgId);
    });

    it('Can search in the location dropdown', () => {
        // find location search box and find "Washington, DC" by term 'wash'
        cy.visit('/dataset');
        cy.get('#dataset-map-edit').find('span').contains('Enter location...').click();
        cy.get('#select2-drop').find('input').type('wash');
        cy.get('#select2-results-1').find('div').contains('Washington, DC').click();
        cy.url().should('include', 'ext_location=Washington%2C+DC+%2820001%29&ext_bbox=-77.0275');
        cy.get('#select2-chosen-1').contains('Washington, DC (20001)');
        cy.contains(/datasets? found/);
    });
});
