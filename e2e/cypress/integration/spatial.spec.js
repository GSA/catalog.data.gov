describe('Spatial', () => {
    it('Can search geographies by name', () => {
        cy.request('/api/3/action/location_search?q=california').should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result[0]).to.have.property('text', 'California');
        });
    });

    it('The map view works and can draw box and search', () => {
        cy.visit('/dataset');
        cy.get('.leaflet-draw-draw-rectangle').click();
        cy.get('#dataset-map-edit-buttons').find('.disabled')
        cy.get('#dataset-map-container')
            .trigger('mousedown', {which: 1})
            .trigger('mousemove', {clientX: 500, clientY: 153})
            .trigger('mouseup');
        // hide the overlaying debugging layer to expose the apply button
        if (cy.get('#flHideToolBarButton')) {
            cy.get('#flHideToolBarButton').click();
        }
        // click the apply button then on the next redirected page find the box
        // on the map and content in the body
        cy.get('#dataset-map-edit-buttons').find('[class="btn apply btn-primary"]').click();
        cy.get('#dataset-map-container').find('svg.leaflet-zoom-animated');
        cy.contains('datasets found');
    });

    it('Can search in the location dropdown', () => {
        // find location search box and find "Washington, DC" by term 'wash'
        cy.visit('/dataset');
        cy.get('#dataset-map-edit').find('span').contains('Enter location...').click();
        cy.get('#select2-drop').find('input').type('wash');
        cy.get('#select2-results-1').find('div').contains('Washington, DC').click();
        cy.url().should('include', 'ext_location=Washington%2C+DC+%2820001%29&ext_bbox=-77.0275');
        cy.get('#select2-chosen-1').contains('Washington, DC (20001)');
        cy.contains('datasets found');
    });

    it('Can put a package with weird tags in an group', () => {
        const group_name = 'climate';
        cy.logout();
        cy.login();
        cy.delete_group(group_name);
        cy.create_group(group_name, "Climate Group");
        cy.request({
            url: '/api/action/package_patch',
            method: 'POST',
            body: {
                "id": "nefsc-2000-spring-bottom-trawl-survey-al0002-ek500",
                "groups": [{"name": group_name}]
            }
        }).should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result.groups[0]).to.have.property("name", "climate");

            // Cleanup
            cy.delete_group(group_name);
            cy.logout();
        })
    })
});