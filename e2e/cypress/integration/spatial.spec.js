describe('Spatial', () => {
    it('Can search geographies by name', () => {
        cy.request('/api/3/action/location_search?q=california').should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result[0]).to.have.property('text', 'California');
        });
    });
    it('The map view works and can filter (start only)', () => {
        cy.visit('/dataset');
        // cy.wait(3);
        // It's really hard to mock clicking on a map and drawing a rectangle;
        //  just start the process and then visit a URL that would result.
        cy.get('.leaflet-draw-draw-rectangle').click();
        cy.wait(1);
        cy.visit('/dataset/?q=&sort=views_recent+desc&ext_location=&ext_bbox=-127.265625%2C25.16517336866393%2C-63.6328125%2C50.51342652633956&ext_prev_extent=-133.2421875%2C5.61598581915534%2C-57.65624999999999%2C60.23981116999893');
        cy.contains('datasets found');

    })
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