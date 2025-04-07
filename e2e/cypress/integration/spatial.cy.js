const group = {
    name: 'climate',
    desc: 'Climate Group'
}
describe('Spatial', { testIsolation: false }, () => {
    before(() => {
        cy.login();
        cy.create_group(group.name, group.desc);        
    });

    after(() => {
        cy.delete_group(group.name);
        cy.logout();
    });

    it('Can search geographies by name', () => {
        cy.request('/api/3/action/location_search?q=california').should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result[0]).to.have.property('text', 'California');
        });
    });

    it('The map view works and can draw box and search', () => {
        cy.visit('/dataset');
        cy.get('.leaflet-control-custom-button').click();
        cy.get('.modal-spatial-query .modal-footer').find('.disabled');
        cy.get('#draw-map-container')
            .trigger('mousedown', { which: 1 })
            .trigger('mousemove', { clientX: 500, clientY: 153 })
            .trigger('mouseup');
        cy.hide_debug_toolbar();
        // click the apply button then on the next redirected page find the box
        // on the map and content in the body
        cy.get('.modal-spatial-query .modal-footer').find('[class="btn btn-primary apply"]').click();
        cy.get('#dataset-map-container').find('svg.leaflet-zoom-animated');
        cy.contains(/No datasets found/);
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

    it('Can put a package in a group', () => {
        let orgId = `org-${cy.helpers.randomSlug()}`;
        let packageId = `package-${orgId}`;
        cy.create_organization(orgId);
        cy.create_dataset({"name": packageId, "owner_org": orgId});
        cy.request({
            url: '/api/action/package_patch',
            method: 'POST',
            body: {
                id: packageId,
                groups: [{ name: group.name }],
            },
        }).should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result.groups[0]).to.have.property('name', group.name);
        });
        cy.delete_dataset(packageId);
        cy.delete_organization(orgId);
    });
});
